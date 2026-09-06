import 'package:equatable/equatable.dart';

/// Parsed metadata object representing dynamic JSONB contents of notifications/requests.
class NotificationMetadata extends Equatable {
  final String? bookingId;
  final String? userId;
  final String? requestType;
  final String? reason;
  final String? notes;
  final String? roomId;
  final String? roomName;
  final String? userName;
  final String? userPhone;
  final String? loungeId;
  final List<Map<String, dynamic>> items;

  const NotificationMetadata({
    this.bookingId,
    this.userId,
    this.requestType,
    this.reason,
    this.notes,
    this.roomId,
    this.roomName,
    this.userName,
    this.userPhone,
    this.loungeId,
    this.items = const [],
  });

  factory NotificationMetadata.fromJson(dynamic json) {
    if (json == null || json is! Map) {
      return const NotificationMetadata();
    }

    final map = Map<String, dynamic>.from(json);

    List<Map<String, dynamic>> parsedItems = [];
    if (map['items'] != null && map['items'] is List) {
      parsedItems = (map['items'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return NotificationMetadata(
      bookingId: map['booking_id']?.toString() ?? map['bookingId']?.toString(),
      userId: map['user_id']?.toString() ?? map['userId']?.toString(),
      requestType: map['request_type']?.toString() ?? map['type']?.toString(),
      reason: map['reason']?.toString(),
      notes: map['notes']?.toString(),
      roomId: map['room_id']?.toString() ?? map['roomId']?.toString(),
      roomName: map['room_name']?.toString() ?? map['roomName']?.toString(),
      userName: map['user_name']?.toString() ?? map['userName']?.toString() ?? map['full_name']?.toString(),
      userPhone: map['user_phone']?.toString() ?? map['userPhone']?.toString() ?? map['phone']?.toString(),
      loungeId: map['lounge_id']?.toString() ?? map['loungeId']?.toString(),
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'user_id': userId,
      'request_type': requestType,
      'reason': reason,
      'notes': notes,
      'room_id': roomId,
      'room_name': roomName,
      'user_name': userName,
      'user_phone': userPhone,
      'lounge_id': loungeId,
      'items': items,
    };
  }

  @override
  List<Object?> get props => [
        bookingId,
        userId,
        requestType,
        reason,
        notes,
        roomId,
        roomName,
        userName,
        userPhone,
        loungeId,
        items,
      ];
}
