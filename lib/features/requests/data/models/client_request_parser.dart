import '../../domain/entities/client_request_entity.dart';
import '../../domain/entities/notification_metadata.dart';
import 'canteen_request_parser.dart';
import 'client_request_model.dart';
import 'service_call_parser.dart';

class ClientRequestParser {
  static int parseInt(dynamic val, int defaultValue) {
    if (val == null) return defaultValue;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? defaultValue;
  }

  static double parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static bool parseBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val == 1;
    if (val is String) {
      final l = val.toLowerCase().trim();
      return l == 'true' || l == '1' || l == 'yes';
    }
    return false;
  }

  static Map<String, dynamic>? parseMap(dynamic val) {
    if (val == null) return null;
    if (val is Map) return Map<String, dynamic>.from(val);
    if (val is List && val.isNotEmpty) {
      final first = val.first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  static ClientRequestModel parseDynamicMap(Map<String, dynamic> map) {
    if (map['id'] == null || map['id'].toString().trim().isEmpty) {
      map['id'] = map['request_id'] ?? map['booking_id'] ?? 'req_${DateTime.now().microsecondsSinceEpoch}';
    }

    final typeStr = (map['type'] ?? map['request_type'] ?? '').toString().toLowerCase();

    if (typeStr.contains('canteen') ||
        typeStr.contains('order') ||
        typeStr.contains('item') ||
        map.containsKey('canteen_orders') ||
        map.containsKey('canteen_items') ||
        map.containsKey('booking_items') ||
        map.containsKey('canteen_order_items')) {
      return parseCanteenOrder(map);
    } else if (typeStr.contains('extend') || typeStr.contains('extension')) {
      return parseBookingExtension(map);
    } else if (typeStr.contains('staff') || typeStr.contains('call') || typeStr.contains('assistance')) {
      return parseServiceCall(map);
    } else {
      return parseNotification(map);
    }
  }

  static ClientRequestModel parseNotification(Map<String, dynamic> json) {
    final metadataObj = NotificationMetadata.fromJson(json['metadata']);
    final rawType = (json['type'] ??
            json['request_type'] ??
            json['category'] ??
            json['call_type'] ??
            json['callType'] ??
            metadataObj.requestType ??
            '')
        .toString()
        .trim()
        .toLowerCase();

    ClientRequestType type;
    switch (rawType) {
      case 'call_staff':
      case 'callstaff':
      case 'staff':
      case 'assistance':
      case 'controller_issue':
      case 'cleaning':
      case 'staff_call':
      case 'room_call':
      case 'help':
        type = ClientRequestType.callStaff;
        break;
      case 'canteen_order':
      case 'canteen':
      case 'order':
      case 'food':
      case 'drink':
        type = ClientRequestType.canteenOrder;
        break;
      case 'extend_session':
      case 'extend':
      case 'extension':
        type = ClientRequestType.extendSession;
        break;
      case 'service':
      case 'service_request':
        type = ClientRequestType.serviceRequest;
        break;
      default:
        final title = (json['title_ar'] ?? json['title'] ?? '').toString().toLowerCase();
        final body = (json['body_ar'] ?? json['body'] ?? '').toString().toLowerCase();
        if (title.contains('عامل') ||
            title.contains('نداء') ||
            title.contains('مساعدة') ||
            title.contains('تنظيف') ||
            title.contains('ذراع') ||
            body.contains('عامل') ||
            body.contains('مساعدة') ||
            title.contains('staff') ||
            title.contains('help')) {
          type = ClientRequestType.callStaff;
        } else {
          type = ClientRequestType.other;
        }
    }

    final statusStr = (json['status'] ?? '').toString().toLowerCase();
    final bool isAttended = parseBool(json['is_attended']) ||
        parseBool(json['attended']) ||
        parseBool(json['is_read']) ||
        parseBool(json['read']) ||
        statusStr == 'completed' ||
        statusStr == 'attended' ||
        statusStr == 'resolved';

    final bool isRead = isAttended || parseBool(json['is_read'] ?? json['read']);

    String bodyAr = (json['body_ar'] ?? json['body'] ?? '').toString();
    if (bodyAr.isEmpty || bodyAr == 'طلب من العميل') {
      if (rawType == 'assistance') {
        bodyAr = 'طلب مساعدة من العامل';
      } else if (rawType == 'controller_issue') {
        bodyAr = 'مشكلة في أجهزة التحكم / الأذرع';
      } else if (rawType == 'cleaning') {
        bodyAr = 'طلب تنظيف المكان';
      } else {
        bodyAr = 'طلب نداء عامل من العميل';
      }
    }

    final String reqId = (json['id'] ?? '').toString();
    final String? userAvatarUrl = (json['user_avatar'] ??
            json['user_avatar_url'] ??
            json['avatar_url'] ??
            metadataObj.userAvatar)
        ?.toString();

    return ClientRequestModel(
      id: reqId,
      loungeId: (json['lounge_id'] ?? json['loungeId'] ?? metadataObj.loungeId ?? '').toString(),
      bookingId: (json['booking_id'] ?? json['bookingId'] ?? metadataObj.bookingId)?.toString(),
      userId: (json['user_id'] ?? json['userId'] ?? metadataObj.userId)?.toString(),
      userName: (json['user_name'] ??
              json['userName'] ??
              json['full_name'] ??
              json['user'] ??
              metadataObj.userName)
          ?.toString(),
      userPhone:
          (json['user_phone'] ?? json['userPhone'] ?? json['phone'] ?? metadataObj.userPhone)?.toString(),
      userAvatarUrl: userAvatarUrl,
      roomId: (json['room_id'] ?? json['roomId'] ?? metadataObj.roomId)?.toString(),
      roomName: (json['room_name'] ?? json['roomName'] ?? json['room'] ?? metadataObj.roomName)?.toString(),
      titleAr: (json['title_ar'] ?? json['title'] ?? 'طلب جديد').toString(),
      titleEn: (json['title_en'] ?? json['title'] ?? 'New Request').toString(),
      bodyAr: bodyAr,
      bodyEn: (json['body_en'] ?? json['body'] ?? 'Client request').toString(),
      type: type,
      isRead: isRead,
      isAttended: isAttended,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      metadata: metadataObj,
      canteenItems: metadataObj.items,
    );
  }

  static ClientRequestModel parseCanteenOrder(Map<String, dynamic> json) {
    return CanteenRequestParser.parse(json);
  }

  static ClientRequestModel parseBookingExtension(Map<String, dynamic> json) {
    final int requestedMinutes = parseInt(
      json['requested_minutes'] ?? json['requested_extension_minutes'] ?? json['extension_minutes'],
      30,
    );
    final int currentDuration = parseInt(json['duration_minutes'], 60);
    final String roomName = (json['room_name'] ?? json['roomName'] ?? json['room'] ?? '').toString();
    final String userName =
        (json['user_name'] ?? json['userName'] ?? json['user'] ?? json['full_name'] ?? '').toString();
    final String? userAvatarUrl =
        (json['user_avatar'] ?? json['user_avatar_url'] ?? json['avatar_url'])?.toString();
    final String extStatus = (json['extension_status'] ?? 'pending').toString().toLowerCase();
    final bool isAttended = extStatus != 'pending';

    final String rawId = (json['id'] ?? '').toString();
    final String reqId = rawId.startsWith('ext_') ? rawId : 'ext_$rawId';

    return ClientRequestModel(
      id: reqId,
      loungeId: (json['lounge_id'] ?? json['loungeId'] ?? '').toString(),
      bookingId: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      userName: userName,
      userPhone: (json['user_phone'] ?? json['userPhone'] ?? json['phone'])?.toString(),
      userAvatarUrl: userAvatarUrl,
      roomId: (json['room_id'] ?? json['roomId'])?.toString(),
      roomName: roomName,
      titleAr: 'طلب تمديد جلسة ($roomName)',
      titleEn: 'Session Extension Request ($roomName)',
      bodyAr: 'العميل $userName يطلب تمديد الجلسة +$requestedMinutes دقيقة',
      bodyEn: 'Client $userName requested +$requestedMinutes mins session extension',
      type: ClientRequestType.extendSession,
      isRead: isAttended,
      isAttended: isAttended,
      createdAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now()),
      metadata: NotificationMetadata(
        bookingId: json['id']?.toString(),
        roomId: (json['room_id'] ?? json['roomId'])?.toString(),
        roomName: roomName,
        userName: userName,
        userPhone: (json['user_phone'] ?? json['userPhone'] ?? json['phone'])?.toString(),
        userAvatar: userAvatarUrl,
        items: [
          {
            'minutes': requestedMinutes,
            'requested_minutes': requestedMinutes,
            'current_duration': currentDuration,
          }
        ],
      ),
    );
  }

  static ClientRequestModel parseServiceCall(
    Map<String, dynamic> json, {
    Map<String, String>? roomNamesMap,
    Map<String, String>? userNamesMap,
    Map<String, String>? userAvatarsMap,
  }) {
    return ServiceCallParser.parse(
      json,
      roomNamesMap: roomNamesMap,
      userNamesMap: userNamesMap,
      userAvatarsMap: userAvatarsMap,
    );
  }

  static ClientRequestModel parseBookingItem(Map<String, dynamic> json) {
    final bookingObj = parseMap(json['bookings']);
    final String name = (json['name'] ?? json['title'] ?? json['item_name'] ?? '').toString();
    final double price = (json['price'] ?? json['unit_price'] as num?)?.toDouble() ?? 0.0;
    final int qty = (json['quantity'] ?? json['qty'] ?? json['count'] as num?)?.toInt() ?? 1;
    final String roomName =
        (bookingObj?['room_name'] ?? json['room_name'] ?? json['roomName'] ?? json['room'] ?? '').toString();
    final String userName =
        (bookingObj?['user_name'] ?? json['user_name'] ?? json['userName'] ?? json['user'] ?? '').toString();
    final String userPhone =
        (bookingObj?['user_phone'] ?? json['user_phone'] ?? json['userPhone'] ?? json['phone'] ?? '').toString();
    final String? userAvatarUrl = (bookingObj?['avatar_url'] ??
            bookingObj?['user_avatar'] ??
            json['user_avatar'] ??
            json['user_avatar_url'] ??
            json['avatar_url'])
        ?.toString();

    final String statusStr = (json['status'] ?? '').toString().toLowerCase();
    final bool isAttended = statusStr == 'completed' ||
        statusStr == 'attended' ||
        statusStr == 'approved' ||
        statusStr == 'resolved' ||
        parseBool(json['is_attended']) ||
        parseBool(json['attended']);

    final itemMap = {
      'name': name,
      'price': price,
      'quantity': qty,
      'note': json['note']?.toString() ?? json['notes']?.toString(),
    };

    final String reqId = (json['id'] ?? '').toString();

    return ClientRequestModel(
      id: reqId,
      loungeId: (bookingObj?['lounge_id'] ?? json['lounge_id'] ?? json['loungeId'] ?? '').toString(),
      bookingId: (json['booking_id'] ?? bookingObj?['id'])?.toString(),
      userId: (json['user_id'] ?? bookingObj?['user_id'])?.toString(),
      userName: userName,
      userPhone: userPhone,
      userAvatarUrl: userAvatarUrl,
      roomId: (json['room_id'] ?? bookingObj?['room_id'])?.toString(),
      roomName: roomName,
      titleAr: 'طلب كافيتريا ($roomName)',
      titleEn: 'Canteen Order ($roomName)',
      bodyAr: 'العميل $userName طلب: $name (عدد $qty)',
      bodyEn: 'Client $userName ordered: $name (x$qty)',
      type: ClientRequestType.canteenOrder,
      isRead: isAttended,
      isAttended: isAttended,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      metadata: NotificationMetadata(
        bookingId: (json['booking_id'] ?? bookingObj?['id'])?.toString(),
        roomId: (json['room_id'] ?? bookingObj?['room_id'])?.toString(),
        roomName: roomName,
        userName: userName,
        userPhone: userPhone,
        userAvatar: userAvatarUrl,
        notes: json['note']?.toString() ?? json['notes']?.toString(),
        items: [itemMap],
      ),
      canteenItems: [itemMap],
      totalPrice: price * qty,
    );
  }
}
