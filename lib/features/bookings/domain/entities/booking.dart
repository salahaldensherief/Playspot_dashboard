import 'package:equatable/equatable.dart';

enum BookingStatus { pending, upcoming, completed, cancelled, inProgress }

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
      ];
}
