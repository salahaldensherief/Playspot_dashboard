import 'package:equatable/equatable.dart';

enum BookingStatus { upcoming, completed, cancelled }

class Booking extends Equatable {
  final String id;
  final String userId;
  final String loungeId;
  final String roomId;
  final String activityId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final BookingStatus status;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.loungeId,
    required this.roomId,
    required this.activityId,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        loungeId,
        roomId,
        activityId,
        startTime,
        endTime,
        totalPrice,
        status,
        createdAt,
      ];
}
