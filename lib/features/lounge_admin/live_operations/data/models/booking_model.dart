import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.loungeId,
    required super.roomId,
    required super.activityId,
    required super.startTime,
    required super.endTime,
    required super.totalPrice,
    required super.status,
    required super.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      userId: json['user_id'],
      loungeId: json['lounge_id'],
      roomId: json['room_id'],
      activityId: json['activity_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      totalPrice: (json['total_price'] as num).toDouble(),
      status: BookingStatus.values.byName(json['status']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lounge_id': loungeId,
      'room_id': roomId,
      'activity_id': activityId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'total_price': totalPrice,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
