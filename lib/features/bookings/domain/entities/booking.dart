import 'package:equatable/equatable.dart';

enum BookingStatus { pending, upcoming, completed, cancelled, past }

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
  final double durationHours;
  final BookingStatus status;
  final String? paymentStatus;
  final double totalPrice;
  final double? voucherDiscount;
  final List<Map<String, dynamic>> extras;
  final String? mapsLink;
  final double? lat;
  final double? lng;

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
    this.durationHours = 0.0,
    required this.status,
    this.paymentStatus,
    required this.totalPrice,
    this.voucherDiscount,
    this.extras = const [],
    this.mapsLink,
    this.lat,
    this.lng,
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
        durationHours,
        status,
        paymentStatus,
        totalPrice,
        voucherDiscount,
        extras,
        mapsLink,
        lat,
        lng,
      ];
}
