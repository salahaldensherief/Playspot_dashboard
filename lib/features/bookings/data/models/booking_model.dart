import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.loungeId,
    required super.roomId,
    super.loungeName = '',
    super.loungeLocation = '',
    super.roomName = '',
    super.controllersCount = 0,
    super.screenSize = '',
    required super.date,
    required super.startTime,
    required super.endTime,
    required super.status,
    required super.totalPrice,
    super.mapsLink,
    super.lat,
    super.lng,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final loungeData = json['lounges'] as Map<String, dynamic>?;
    final roomData = json['rooms'] as Map<String, dynamic>?;

    String statusStr = json['status'] ?? 'past';
    BookingStatus status;
    switch (statusStr) {
      case 'upcoming':
        status = BookingStatus.upcoming;
        break;
      case 'completed':
        status = BookingStatus.completed;
        break;
      case 'cancelled':
        status = BookingStatus.cancelled;
        break;
      case 'past':
        status = BookingStatus.past;
        break;
      default:
        status = BookingStatus.past;
    }

    return BookingModel(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      loungeId: json['lounge_id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      loungeName: loungeData?['name'] ?? '',
      loungeLocation: loungeData?['location'] ?? '',
      roomName: roomData?['name_en'] ?? roomData?['name'] ?? '',
      controllersCount: roomData?['controllers_count'] ?? 0,
      screenSize: roomData?['screen_size'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: status,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      mapsLink: loungeData?['maps_link'],
      lat: (loungeData?['lat'] as num?)?.toDouble(),
      lng: (loungeData?['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lounge_id': loungeId,
      'room_id': roomId,
      'date': date.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'status': status.name,
      'total_price': totalPrice,
    };
  }
}
