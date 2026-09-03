import 'package:equatable/equatable.dart';

/// Parsed metadata object representing dynamic JSONB contents of notifications/requests.
class NotificationMetadata extends Equatable {
  final String? bookingId;
  final String? requestType;
  final String? reason;
  final String? notes;
  final String? roomId;
  final String? roomName;
  final List<Map<String, dynamic>> items;

  const NotificationMetadata({
    this.bookingId,
    this.requestType,
    this.reason,
    this.notes,
    this.roomId,
    this.roomName,
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
      requestType: map['request_type']?.toString() ?? map['type']?.toString(),
      reason: map['reason']?.toString(),
      notes: map['notes']?.toString(),
      roomId: map['room_id']?.toString() ?? map['roomId']?.toString(),
      roomName: map['room_name']?.toString() ?? map['roomName']?.toString(),
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'request_type': requestType,
      'reason': reason,
      'notes': notes,
      'room_id': roomId,
      'room_name': roomName,
      'items': items,
    };
  }

  @override
  List<Object?> get props => [
        bookingId,
        requestType,
        reason,
        notes,
        roomId,
        roomName,
        items,
      ];
}
