import '../../domain/entities/client_request_entity.dart';
import '../../domain/entities/notification_metadata.dart';
import 'client_request_model.dart';
import 'client_request_parser.dart';

class ServiceCallParser {
  static ClientRequestModel parse(
    Map<String, dynamic> json, {
    Map<String, String>? roomNamesMap,
    Map<String, String>? userNamesMap,
    Map<String, String>? userAvatarsMap,
  }) {
    final statusStr = (json['status'] ?? 'pending').toString().toLowerCase();
    final bool isAttended = statusStr == 'resolved' ||
        statusStr == 'completed' ||
        statusStr == 'attended' ||
        statusStr == 'approved' ||
        ClientRequestParser.parseBool(json['is_attended']);
    final bool isRead = isAttended || ClientRequestParser.parseBool(json['is_read']);

    final String reqId = (json['id'] ?? '').toString();
    final String callType = (json['call_type'] ?? json['type'] ?? 'assistance').toString().toLowerCase();
    String bodyAr = 'طلب مساعدة من العامل';
    if (json['reason'] != null && json['reason'].toString().trim().isNotEmpty) {
      bodyAr = json['reason'].toString().trim();
    } else if (json['note'] != null && json['note'].toString().trim().isNotEmpty) {
      bodyAr = json['note'].toString().trim();
    } else if (json['notes'] != null && json['notes'].toString().trim().isNotEmpty) {
      bodyAr = json['notes'].toString().trim();
    } else if (json['message'] != null && json['message'].toString().trim().isNotEmpty) {
      bodyAr = json['message'].toString().trim();
    } else if (callType == 'controller_issue') {
      bodyAr = 'مشكلة في أجهزة التحكم / الأذرع';
    } else if (callType == 'cleaning') {
      bodyAr = 'طلب تنظيف المكان';
    }

    final roomObj = ClientRequestParser.parseMap(json['rooms']);
    final bookingObj = ClientRequestParser.parseMap(json['bookings']);

    final roomId = (json['room_id'] ?? json['roomId'] ?? bookingObj?['room_id'])?.toString();
    final bookingId = (json['booking_id'] ?? json['bookingId'] ?? bookingObj?['id'])?.toString();
    final userId = (json['user_id'] ?? json['userId'] ?? bookingObj?['user_id'])?.toString();

    String roomName = (bookingObj?['room_name'] ??
            roomObj?['name'] ??
            json['room_name'] ??
            json['roomName'] ??
            json['room'] ??
            '')
        .toString();
    if (roomName.isEmpty && roomId != null && roomNamesMap != null) {
      roomName = roomNamesMap[roomId] ?? '';
    }

    String userName = (bookingObj?['user_name'] ??
            json['user_name'] ??
            json['userName'] ??
            json['user'] ??
            json['full_name'] ??
            '')
        .toString();
    if (userName.isEmpty && bookingId != null && userNamesMap != null) {
      userName = userNamesMap[bookingId] ?? '';
    }
    if (userName.isEmpty) {
      userName = 'عميل';
    }

    String? userAvatarUrl = (json['user_avatar'] ??
            json['user_avatar_url'] ??
            json['avatar_url'] ??
            bookingObj?['avatar_url'] ??
            bookingObj?['user_avatar'])
        ?.toString();
    if ((userAvatarUrl == null || userAvatarUrl.isEmpty) && userAvatarsMap != null) {
      if (bookingId != null && userAvatarsMap.containsKey(bookingId)) {
        userAvatarUrl = userAvatarsMap[bookingId];
      }
      if ((userAvatarUrl == null || userAvatarUrl.isEmpty) && userId != null && userAvatarsMap.containsKey(userId)) {
        userAvatarUrl = userAvatarsMap[userId];
      }
    }

    return ClientRequestModel(
      id: reqId,
      loungeId: (json['lounge_id'] ?? json['loungeId'] ?? bookingObj?['lounge_id'] ?? '').toString(),
      bookingId: bookingId,
      userId: userId,
      userName: userName,
      userPhone: (bookingObj?['user_phone'] ?? json['user_phone'] ?? json['userPhone'] ?? json['phone'])?.toString(),
      userAvatarUrl: userAvatarUrl,
      roomId: roomId,
      roomName: roomName.isNotEmpty ? roomName : null,
      titleAr: roomName.isNotEmpty ? 'نداء خدمة ($roomName)' : 'نداء خدمة / مساعدة',
      titleEn: roomName.isNotEmpty ? 'Service Call ($roomName)' : 'Service Call Request',
      bodyAr: bodyAr,
      bodyEn: 'Customer requested staff assistance',
      type: ClientRequestType.callStaff,
      isRead: isRead,
      isAttended: isAttended,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      metadata: NotificationMetadata(
        bookingId: bookingId,
        roomId: roomId,
        roomName: roomName,
        userName: userName,
        userPhone: (bookingObj?['user_phone'] ?? json['user_phone'] ?? json['userPhone'] ?? json['phone'])?.toString(),
        userAvatar: userAvatarUrl,
        notes: json['notes']?.toString(),
      ),
    );
  }
}
