import 'package:equatable/equatable.dart';
import 'booking_status.dart';
import 'payment_enums.dart';

export 'booking_status.dart';
export 'payment_enums.dart';

class Booking extends Equatable {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String loungeId;
  final String roomId;
  final String loungeName;
  final String loungeLocation;
  final String roomName;
  final int controllersCount;
  final String screenSize;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final double totalPrice;
  final double? addonsPrice;
  final double? voucherDiscount;
  final String? voucherCode;
  final double? discountAmount;
  final double? discountPercentage;
  final String? discountReason;
  final List<Map<String, dynamic>> extras;
  final List<Map<String, dynamic>> canteenOrders;
  final double? lat;
  final double? lng;
  final String? shiftId;
  final String? playMode;
  final double? roomPrice;
  final int? visitNumber;
  final String? paymentMethod;
  final String? receiptUrl;
  final DateTime? expiresAt;
  final bool isFirstBooking;
  final String? senderWalletPhone;
  final DateTime? checkedInAt;
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? cancelledAt;

  const Booking({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    required this.loungeId,
    required this.roomId,
    this.loungeName = '',
    this.loungeLocation = '',
    this.roomName = '',
    this.controllersCount = 0,
    this.screenSize = '',
    required this.date,
    required this.startTime,
    required this.endTime,
    this.durationMinutes = 60,
    required this.status,
    this.paymentStatus = PaymentStatus.unpaid,
    required this.totalPrice,
    this.addonsPrice,
    this.voucherDiscount,
    this.voucherCode,
    this.discountAmount,
    this.discountPercentage,
    this.discountReason,
    this.extras = const [],
    this.canteenOrders = const [],
    this.lat,
    this.lng,
    this.shiftId,
    this.playMode,
    this.roomPrice,
    this.visitNumber,
    this.paymentMethod,
    this.receiptUrl,
    this.expiresAt,
    this.isFirstBooking = false,
    this.senderWalletPhone,
    this.checkedInAt,
    this.cancellationReason,
    this.cancelledBy,
    this.cancelledAt,
  });

  bool get isOpenEnded => durationMinutes <= 0;

  /// Helper to determine if booking was cancelled by the client after approval
  bool get isCancelledByClient =>
      status == BookingStatus.cancelled &&
      cancelledBy != null &&
      cancelledBy!.trim().isNotEmpty &&
      cancelledBy!.trim() == userId.trim();

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userEmail,
        userPhone,
        loungeId,
        roomId,
        loungeName,
        loungeLocation,
        roomName,
        controllersCount,
        screenSize,
        date,
        startTime,
        endTime,
        durationMinutes,
        status,
        paymentStatus,
        totalPrice,
        addonsPrice,
        voucherDiscount,
        voucherCode,
        discountAmount,
        discountPercentage,
        discountReason,
        extras,
        canteenOrders,
        lat,
        lng,
        shiftId,
        playMode,
        roomPrice,
        visitNumber,
        paymentMethod,
        receiptUrl,
        expiresAt,
        isFirstBooking,
        senderWalletPhone,
        checkedInAt,
        cancellationReason,
        cancelledBy,
        cancelledAt,
      ];

  Booking copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? loungeId,
    String? roomId,
    String? loungeName,
    String? loungeLocation,
    String? roomName,
    int? controllersCount,
    String? screenSize,
    DateTime? date,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    double? totalPrice,
    double? addonsPrice,
    double? voucherDiscount,
    String? voucherCode,
    double? discountAmount,
    double? discountPercentage,
    String? discountReason,
    List<Map<String, dynamic>>? extras,
    List<Map<String, dynamic>>? canteenOrders,
    double? lat,
    double? lng,
    String? shiftId,
    String? playMode,
    double? roomPrice,
    int? visitNumber,
    String? paymentMethod,
    String? receiptUrl,
    DateTime? expiresAt,
    bool? isFirstBooking,
    String? senderWalletPhone,
    DateTime? checkedInAt,
    String? cancellationReason,
    String? cancelledBy,
    DateTime? cancelledAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      loungeId: loungeId ?? this.loungeId,
      roomId: roomId ?? this.roomId,
      loungeName: loungeName ?? this.loungeName,
      loungeLocation: loungeLocation ?? this.loungeLocation,
      roomName: roomName ?? this.roomName,
      controllersCount: controllersCount ?? this.controllersCount,
      screenSize: screenSize ?? this.screenSize,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalPrice: totalPrice ?? this.totalPrice,
      addonsPrice: addonsPrice ?? this.addonsPrice,
      voucherDiscount: voucherDiscount ?? this.voucherDiscount,
      voucherCode: voucherCode ?? this.voucherCode,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountReason: discountReason ?? this.discountReason,
      extras: extras ?? this.extras,
      canteenOrders: canteenOrders ?? this.canteenOrders,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      shiftId: shiftId ?? this.shiftId,
      playMode: playMode ?? this.playMode,
      roomPrice: roomPrice ?? this.roomPrice,
      visitNumber: visitNumber ?? this.visitNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      expiresAt: expiresAt ?? this.expiresAt,
      isFirstBooking: isFirstBooking ?? this.isFirstBooking,
      senderWalletPhone: senderWalletPhone ?? this.senderWalletPhone,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  /// Helper to determine if booking is cash or manual transfer
  bool get isCashPayment {
    final pm = (paymentMethod ?? 'cash').toLowerCase().trim();
    return pm == 'cash' || pm.isEmpty;
  }

  bool get isManualTransfer {
    final pm = (paymentMethod ?? '').toLowerCase().trim();
    return pm == 'manual_transfer' || pm == 'manual' || pm == 'wallet' || pm == 'vodafone_cash' || pm == 'instapay';
  }

  bool get isWalletPayment => isManualTransfer;

  String get displayWalletInfo {
    if (senderWalletPhone != null && senderWalletPhone!.trim().isNotEmpty) {
      return senderWalletPhone!.trim();
    }
    if (userPhone != null && userPhone!.trim().isNotEmpty) {
      return userPhone!.trim();
    }
    return 'تحويل يدوي';
  }

  /// Calculates the exact start [DateTime] combining [date] and [startTime].
  DateTime? get startDateTime {
    if (startTime.trim().isEmpty) return null;
    try {
      final parts = startTime.trim().split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
    } catch (_) {}
    return null;
  }

  /// Calculates the exact end [DateTime].
  /// Prefers calculating [startDateTime] + [durationMinutes] when available,
  /// otherwise falls back to parsing [endTime].
  DateTime? get endDateTime {
    final start = startDateTime;

    if (start != null && durationMinutes > 0) {
      return start.add(Duration(minutes: durationMinutes));
    }

    if (endTime.trim().isNotEmpty) {
      try {
        final cleanEndTime = endTime.trim();
        if (cleanEndTime.contains('T')) {
          final parsed = DateTime.tryParse(cleanEndTime);
          if (parsed != null) return parsed;
        }
        final parts = cleanEndTime.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          var end = DateTime(date.year, date.month, date.day, hour, minute);
          if (start != null && (end.isBefore(start) || end.isAtSameMomentAs(start))) {
            end = end.add(const Duration(days: 1));
          }
          return end;
        }
      } catch (_) {}
    }

    if (start == null) return null;
    return start.add(Duration(minutes: durationMinutes));
  }

  /// Determines if the booking is currently active in real-time.
  bool isBookingActive([DateTime? now]) {
    if (status == BookingStatus.completed || status == BookingStatus.cancelled) {
      return false;
    }
    if (status == BookingStatus.inProgress) {
      return true;
    }
    final currentTime = now ?? DateTime.now();
    final end = endDateTime;
    final start = startDateTime;
    if (end == null || start == null) return false;

    return (currentTime.isAfter(start) || currentTime.isAtSameMomentAs(start)) &&
        currentTime.isBefore(end);
  }

  /// Checks if the session or cash hold has expired.
  /// For pending bookings, uses [expiresAt] as hold expiration if available.
  /// For active/upcoming sessions, calculates end time + grace period.
  bool isSessionExpired([DateTime? now, Duration gracePeriod = const Duration(minutes: 5)]) {
    final currentTime = now ?? DateTime.now();
    final holdExpiry = expiresAt;
    if (status == BookingStatus.pending && holdExpiry != null) {
      return currentTime.isAfter(holdExpiry) || currentTime.isAtSameMomentAs(holdExpiry);
    }
    final end = endDateTime;
    if (end == null) return false;
    final endWithGrace = end.add(gracePeriod);
    return currentTime.isAfter(endWithGrace) || currentTime.isAtSameMomentAs(endWithGrace);
  }

  /// Alias for checking if hold grace period has expired using [expiresAt] SSOT
  bool get isGraceExpired => isSessionExpired();

  /// Helper to get remaining duration based on real-world clock.
  Duration remainingDuration([DateTime? now]) {
    final end = endDateTime;
    if (end == null) return Duration.zero;
    final currentTime = now ?? DateTime.now();
    return end.difference(currentTime);
  }
}
