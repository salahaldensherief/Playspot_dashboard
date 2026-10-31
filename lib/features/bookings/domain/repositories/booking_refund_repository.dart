enum RefundFailureKind {
  unavailable,
  denied,
  rejected,
  uncertain,
  pending,
  invalid,
}

class RefundFailure implements Exception {
  final RefundFailureKind kind;
  const RefundFailure(this.kind);
}

class RefundMovement {
  final String id, operationId, type, method, holder;
  final String? reversalOf;
  final int amountMinor;
  const RefundMovement({
    required this.id,
    required this.operationId,
    required this.type,
    required this.method,
    required this.holder,
    required this.amountMinor,
    this.reversalOf,
  });
  bool get supportsCashReturn =>
      type == 'collection' && method == 'cash' && holder == 'lounge';
}

class BookingRefundRequest {
  final String id, operationId, collectionId, holder, status;
  final String? refundMovementId;
  final int amountMinor;
  const BookingRefundRequest({
    required this.id,
    required this.operationId,
    required this.collectionId,
    required this.holder,
    required this.status,
    required this.amountMinor,
    this.refundMovementId,
  });
}

class BookingRefundSummary {
  final String bookingId, loungeId;
  final int grossMinor, refundedMinor, netMinor, pendingMinor, remainingMinor;
  final List<RefundMovement> movements;
  final List<BookingRefundRequest> requests;
  const BookingRefundSummary({
    required this.bookingId,
    required this.loungeId,
    required this.grossMinor,
    required this.refundedMinor,
    required this.netMinor,
    required this.pendingMinor,
    required this.remainingMinor,
    required this.movements,
    required this.requests,
  });

  // A preview only: policy, current reservations and payout locks are server owned.
  int availableFor(RefundMovement collection) {
    final returned = movements
        .where((m) => m.reversalOf == collection.id)
        .fold(0, (sum, m) => sum - m.amountMinor);
    final reserved = requests
        .where(
          (r) =>
              r.collectionId == collection.id &&
              r.status == 'approved_pending_return',
        )
        .fold(0, (sum, r) => sum + r.amountMinor);
    return (collection.amountMinor - returned - reserved).clamp(
      0,
      collection.amountMinor,
    );
  }
}

class RefundReceipt {
  final String operationId, requestId;
  final String? movementId;
  final int amountMinor;
  const RefundReceipt(
    this.operationId,
    this.requestId,
    this.amountMinor, {
    this.movementId,
  });
  bool get moneyReturned => movementId != null;
}

abstract class BookingRefundRepository {
  bool get writesEnabled;
  Future<BookingRefundSummary> summary(String bookingId, String loungeId);
  Future<RefundReceipt> initiate({
    required BookingRefundSummary summary,
    required String collectionId,
    required int amountMinor,
    required String reason,
    required bool policyOverride,
  });
  Future<RefundReceipt> execute({
    required BookingRefundSummary summary,
    required BookingRefundRequest request,
    required String shiftId,
    required String evidence,
  });
}

/// Parses decimal money without floating-point rounding or silently truncating cents.
int? refundAmountMinor(String value) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  var normalized = value.trim().replaceAll('٫', '.');
  for (var i = 0; i < arabic.length; i++) {
    normalized = normalized.replaceAll(arabic[i], '$i');
  }
  if (!RegExp(r'^\d{1,12}(\.\d{1,2})?$').hasMatch(normalized)) return null;
  final parts = normalized.split('.');
  final result =
      int.parse(parts[0]) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  return result > 0 ? result : null;
}
