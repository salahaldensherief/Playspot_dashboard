import 'package:equatable/equatable.dart';

enum BookingStatus { pending, upcoming, completed, cancelled, past }

class Booking extends Equatable {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
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
  final BookingStatus status;
  final String? paymentStatus;
  final double totalPrice;
  final String? mapsLink;
  final double? lat;
  final double? lng;

  const Booking({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
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
    required this.status,
    this.paymentStatus,
    required this.totalPrice,
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
        status,
        paymentStatus,
        totalPrice,
        mapsLink,
        lat,
        lng,
      ];
}
