import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/booking_refund_repository.dart';

class BookingRefundState {
  final BookingRefundSummary? summary;
  final RefundReceipt? receipt;
  final RefundFailureKind? error;
  final bool busy, fresh;
  const BookingRefundState({
    this.summary,
    this.receipt,
    this.error,
    this.busy = false,
    this.fresh = false,
  });
}

class BookingRefundCubit extends Cubit<BookingRefundState> {
  final BookingRefundRepository repository;
  final String bookingId, loungeId;
  BookingRefundCubit(this.repository, this.bookingId, this.loungeId)
    : super(const BookingRefundState());

  Future<void> load() async {
    if (state.busy) return;
    emit(
      BookingRefundState(
        summary: state.summary,
        receipt: state.receipt,
        busy: true,
      ),
    );
    await _refresh(state.receipt);
  }

  Future<void> _refresh(RefundReceipt? receipt) async {
    try {
      final summary = await repository.summary(bookingId, loungeId);
      if (!isClosed) {
        emit(
          BookingRefundState(summary: summary, receipt: receipt, fresh: true),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          BookingRefundState(
            summary: state.summary,
            receipt: receipt,
            error: e is RefundFailure ? e.kind : RefundFailureKind.unavailable,
          ),
        );
      }
    }
  }

  Future<void> _write(
    Future<RefundReceipt> Function(BookingRefundSummary) action,
  ) async {
    if (state.busy ||
        !state.fresh ||
        state.summary == null ||
        !repository.writesEnabled) {
      return;
    }
    final summary = state.summary!;
    emit(BookingRefundState(summary: summary, busy: true));
    try {
      final receipt = await action(summary);
      if (!isClosed) await _refresh(receipt);
    } catch (e) {
      if (!isClosed) {
        emit(
          BookingRefundState(
            summary: summary,
            error: e is RefundFailure ? e.kind : RefundFailureKind.uncertain,
          ),
        );
      }
    }
  }

  Future<void> initiate(
    String collectionId,
    int amount,
    String reason,
    bool policyOverride,
  ) => _write(
    (s) => repository.initiate(
      summary: s,
      collectionId: collectionId,
      amountMinor: amount,
      reason: reason,
      policyOverride: policyOverride,
    ),
  );
  Future<void> execute(
    BookingRefundRequest request,
    String shift,
    String evidence,
  ) => _write(
    (s) => repository.execute(
      summary: s,
      request: request,
      shiftId: shift,
      evidence: evidence,
    ),
  );
}
