import '../../domain/entities/client_request_entity.dart';
import '../../domain/entities/notification_metadata.dart';

class ClientRequestModel extends ClientRequestEntity {
  const ClientRequestModel({
    required super.id,
    required super.loungeId,
    super.bookingId,
    super.userId,
    super.userName,
    super.userPhone,
    super.userAvatarUrl,
    super.roomId,
    super.roomName,
    required super.titleAr,
    required super.titleEn,
    required super.bodyAr,
    required super.bodyEn,
    required super.type,
    super.isRead = false,
    super.isAttended = false,
    required super.createdAt,
    super.metadata = const NotificationMetadata(),
    super.canteenItems = const [],
    super.totalPrice,
  });

  static int _parseInt(dynamic val, int defaultValue) {
    if (val == null) return defaultValue;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? defaultValue;
  }

  static bool _parseBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val == 1;
    if (val is String) {
      final l = val.toLowerCase().trim();
      return l == 'true' || l == '1' || l == 'yes';
    }
    return false;
  }

  static Map<String, dynamic>? _parseMap(dynamic val) {
    if (val == null) return null;
    if (val is Map) return Map<String, dynamic>.from(val);
    if (val is List && val.isNotEmpty) {
      final first = val.first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  factory ClientRequestModel.fromNotificationJson(Map<String, dynamic> json) {
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
    final bool isAttended = _parseBool(json['is_attended']) ||
        _parseBool(json['attended']) ||
        _parseBool(json['is_read']) ||
        _parseBool(json['read']) ||
        statusStr == 'completed' ||
        statusStr == 'attended' ||
        statusStr == 'resolved';

    final bool isRead = isAttended || _parseBool(json['is_read'] ?? json['read']);

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
      userName: (json['user_name'] ?? json['userName'] ?? json['full_name'] ?? json['user'] ?? metadataObj.userName)?.toString(),
      userPhone: (json['user_phone'] ?? json['userPhone'] ?? json['phone'] ?? metadataObj.userPhone)?.toString(),
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

  factory ClientRequestModel.fromCanteenOrderJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final metadataObj = NotificationMetadata.fromJson(json['metadata']);

    List<Map<String, dynamic>> parsedItems = [];
    if (json['canteen_order_items'] != null && json['canteen_order_items'] is List) {
      parsedItems = (json['canteen_order_items'] as List)
          .whereType<Map>()
          .map((i) => Map<String, dynamic>.from(i))
          .toList();
    } else if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .whereType<Map>()
          .map((i) => Map<String, dynamic>.from(i))
          .toList();
    } else if (json['canteen_items'] != null && json['canteen_items'] is List) {
      parsedItems = (json['canteen_items'] as List)
          .whereType<Map>()
          .map((i) => Map<String, dynamic>.from(i))
          .toList();
    } else if (metadataObj.items.isNotEmpty) {
      parsedItems = metadataObj.items;
    }

    final String statusStr = (json['status'] ?? 'pending').toString().toLowerCase();
    final bool isAttended = statusStr == 'completed' ||
        statusStr == 'attended' ||
        statusStr == 'approved' ||
        statusStr == 'resolved' ||
        _parseBool(json['is_attended']) ||
        _parseBool(json['attended']);

    final String roomName = (json['room_name'] ?? json['roomName'] ?? json['room'] ?? metadataObj.roomName ?? 'Gaming Station').toString();
    final String userName = (json['user_name'] ?? json['userName'] ?? json['user'] ?? json['full_name'] ?? metadataObj.userName ?? 'Client').toString();
    final String userPhone = (json['user_phone'] ?? json['userPhone'] ?? json['phone'] ?? metadataObj.userPhone ?? '').toString();
    final String? userAvatarUrl = (json['user_avatar'] ?? json['user_avatar_url'] ?? json['avatar_url'] ?? metadataObj.userAvatar)?.toString();

    final String reqId = (json['id'] ?? '').toString();

    return ClientRequestModel(
      id: reqId,
      loungeId: (json['lounge_id'] ?? json['loungeId'] ?? metadataObj.loungeId ?? '').toString(),
      bookingId: (json['booking_id'] ?? json['bookingId'] ?? metadataObj.bookingId)?.toString(),
      userId: (json['user_id'] ?? json['userId'] ?? metadataObj.userId)?.toString(),
      userName: userName,
      userPhone: userPhone,
      userAvatarUrl: userAvatarUrl,
      roomId: (json['room_id'] ?? json['roomId'] ?? metadataObj.roomId)?.toString(),
      roomName: roomName,
      titleAr: 'طلب كافيتريا ($roomName)',
      titleEn: 'Canteen Order ($roomName)',
      bodyAr: 'العميل $userName طلب أصناف من المنيو',
      bodyEn: 'Client $userName ordered menu items',
      type: ClientRequestType.canteenOrder,
      isRead: isAttended,
      isAttended: isAttended,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      metadata: NotificationMetadata(
        bookingId: (json['booking_id'] ?? json['bookingId'] ?? metadataObj.bookingId)?.toString(),
        roomId: (json['room_id'] ?? json['roomId'] ?? metadataObj.roomId)?.toString(),
        roomName: roomName,
        userName: userName,
        userPhone: userPhone,
        userAvatar: userAvatarUrl,
        notes: json['notes']?.toString() ?? json['note']?.toString(),
        items: parsedItems,
      ),
      canteenItems: parsedItems,
      totalPrice: parseDouble(json['total_price'] ?? json['price'] ?? json['amount']),
    );
  }

  factory ClientRequestModel.fromBookingExtensionJson(Map<String, dynamic> json) {
    final int requestedMinutes = _parseInt(
      json['requested_minutes'] ?? json['requested_extension_minutes'] ?? json['extension_minutes'],
      30,
    );
    final int currentDuration = _parseInt(json['duration_minutes'], 60);
    final String roomName = (json['room_name'] ?? json['roomName'] ?? json['room'] ?? 'Station').toString();
    final String userName = (json['user_name'] ?? json['userName'] ?? json['user'] ?? json['full_name'] ?? 'Client').toString();
    final String? userAvatarUrl = (json['user_avatar'] ?? json['user_avatar_url'] ?? json['avatar_url'])?.toString();
    final String extStatus = (json['extension_status'] ?? 'pending').toString().toLowerCase();
    final bool isAttended = extStatus != 'pending';

    final String reqId = (json['id'] ?? '').toString();

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

  factory ClientRequestModel.fromServiceCallJson(
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
        _parseBool(json['is_attended']);
    final bool isRead = isAttended || _parseBool(json['is_read']);

    final String reqId = (json['id'] ?? '').toString();

    final String callType = (json['call_type'] ?? json['type'] ?? 'assistance').toString().toLowerCase();
    String bodyAr = 'طلب مساعدة من العامل';
    if (callType == 'controller_issue') {
      bodyAr = 'مشكلة في أجهزة التحكم / الأذرع';
    } else if (callType == 'cleaning') {
      bodyAr = 'طلب تنظيف المكان';
    } else if (json['notes'] != null && json['notes'].toString().isNotEmpty) {
      bodyAr = json['notes'].toString();
    }

    final roomObj = _parseMap(json['rooms']);
    final bookingObj = _parseMap(json['bookings']);

    final roomId = (json['room_id'] ?? json['roomId'] ?? bookingObj?['room_id'])?.toString();
    final bookingId = (json['booking_id'] ?? json['bookingId'] ?? bookingObj?['id'])?.toString();
    final userId = (json['user_id'] ?? json['userId'] ?? bookingObj?['user_id'])?.toString();

    String roomName = (bookingObj?['room_name'] ?? roomObj?['name'] ?? json['room_name'] ?? json['roomName'] ?? json['room'] ?? '').toString();
    if (roomName.isEmpty && roomId != null && roomNamesMap != null) {
      roomName = roomNamesMap[roomId] ?? '';
    }

    String userName = (bookingObj?['user_name'] ?? json['user_name'] ?? json['userName'] ?? json['user'] ?? json['full_name'] ?? '').toString();
    if (userName.isEmpty && bookingId != null && userNamesMap != null) {
      userName = userNamesMap[bookingId] ?? '';
    }
    if (userName.isEmpty) {
      userName = 'عميل';
    }

    String? userAvatarUrl = (json['user_avatar'] ?? json['user_avatar_url'] ?? json['avatar_url'] ?? bookingObj?['avatar_url'] ?? bookingObj?['user_avatar'])?.toString();
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
      createdAt: json['created_at'] != null ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()) : DateTime.now(),
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

  factory ClientRequestModel.fromBookingItemJson(Map<String, dynamic> json) {
    final bookingObj = _parseMap(json['bookings']);
    final String name = (json['name'] ?? json['title'] ?? json['item_name'] ?? 'Canteen Item').toString();
    final double price = (json['price'] ?? json['unit_price'] as num?)?.toDouble() ?? 0.0;
    final int qty = (json['quantity'] ?? json['qty'] ?? json['count'] as num?)?.toInt() ?? 1;
    final String roomName = (bookingObj?['room_name'] ?? json['room_name'] ?? json['roomName'] ?? json['room'] ?? 'Gaming Station').toString();
    final String userName = (bookingObj?['user_name'] ?? json['user_name'] ?? json['userName'] ?? json['user'] ?? 'Client').toString();
    final String userPhone = (bookingObj?['user_phone'] ?? json['user_phone'] ?? json['userPhone'] ?? json['phone'] ?? '').toString();
    final String? userAvatarUrl = (bookingObj?['avatar_url'] ?? bookingObj?['user_avatar'] ?? json['user_avatar'] ?? json['user_avatar_url'] ?? json['avatar_url'])?.toString();

    final String statusStr = (json['status'] ?? '').toString().toLowerCase();
    final bool isAttended = statusStr == 'completed' ||
        statusStr == 'attended' ||
        statusStr == 'approved' ||
        statusStr == 'resolved' ||
        _parseBool(json['is_attended']) ||
        _parseBool(json['attended']);

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