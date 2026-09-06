import 'package:equatable/equatable.dart';

enum BookingStatus { pending, upcoming, completed, cancelled, inProgress }

extension BookingStatusX on BookingStatus {
  String toDbString() {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.upcoming:
        return 'upcoming';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.inProgress:
        return 'in_progress';
    }
  }

  static BookingStatus fromString(String? status) {
    if (status == null) return BookingStatus.pending;
    final clean = status.trim().toLowerCase().replaceAll(' ', '_');
    switch (clean) {
      case 'upcoming':
        return BookingStatus.upcoming;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
      case 'canceled':
      case 'rejected':
      case 'reject':
      case 'no_show':
      case 'noshow':
        return BookingStatus.cancelled;
      case 'in_progress':
      case 'inprogress':
      case 'active':
        return BookingStatus.inProgress;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }
}

enum PaymentStatus { unpaid, paid, refunded }

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
  final double? voucherDiscount;
  final double? discountAmount;
  final double? discountPercentage;
  final String? discountReason;
  final List<Map<String, dynamic>> extras;
  final double? lat;
  final double? lng;
  final String? shiftId;
  final String? playMode;
  final double? roomPrice;

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
    this.voucherDiscount,
    this.discountAmount,
    this.discountPercentage,
    this.discountReason,
    this.extras = const [],
    this.lat,
    this.lng,
    this.shiftId,
    this.playMode,
    this.roomPrice,
  });

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
        voucherDiscount,
        discountAmount,
        discountPercentage,
        discountReason,
        extras,
        lat,
        lng,
        shiftId,
        playMode,
        roomPrice,
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
    double? voucherDiscount,
    double? discountAmount,
    double? discountPercentage,
    String? discountReason,
    List<Map<String, dynamic>>? extras,
    double? lat,
    double? lng,
    String? shiftId,
    String? playMode,
    double? roomPrice,
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
      voucherDiscount: voucherDiscount ?? this.voucherDiscount,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountReason: discountReason ?? this.discountReason,
      extras: extras ?? this.extras,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      shiftId: shiftId ?? this.shiftId,
      playMode: playMode ?? this.playMode,
      roomPrice: roomPrice ?? this.roomPrice,
    );
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
  /// Uses parsed [endTime] if available, otherwise calculates [startDateTime] + [durationMinutes].
  /// Handles ISO string formats and overnight sessions.
  DateTime? get endDateTime {
    final start = startDateTime;

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
  ///
  /// A booking/room is ONLY considered active if:
  /// 1. Its status is [BookingStatus.inProgress].
  /// 2. The reference time [now] (defaults to [DateTime.now()]) is strictly between [startDateTime] and [endDateTime].
  /// Once [now] passes [endDateTime] (now >= endDateTime), [isBookingActive] returns `false`.
  bool isBookingActive([DateTime? now]) {
    if (status == BookingStatus.completed || status == BookingStatus.cancelled) {
      return false;
    }
    final currentTime = now ?? DateTime.now();
    final end = endDateTime;
    final start = startDateTime;
    if (end == null || start == null) return false;

    if (currentTime.isAfter(end) || currentTime.isAtSameMomentAs(end)) {
      return false;
    }

    if (currentTime.isBefore(start)) {
      return false;
    }

    return status == BookingStatus.inProgress;
  }

  /// Checks if the session has expired beyond an optional grace period (default 5 minutes).
  bool isSessionExpired([DateTime? now, Duration gracePeriod = const Duration(minutes: 5)]) {
    final currentTime = now ?? DateTime.now();
    final end = endDateTime;
    if (end == null) return false;
    final endWithGrace = end.add(gracePeriod);
    return currentTime.isAfter(endWithGrace) || currentTime.isAtSameMomentAs(endWithGrace);
  }

  /// Helper to get remaining duration based on real-world clock.
  Duration remainingDuration([DateTime? now]) {
    final end = endDateTime;
    if (end == null) return Duration.zero;
    final currentTime = now ?? DateTime.now();
    return end.difference(currentTime);
  }
}
