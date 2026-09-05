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

    final bool isRead = _parseBool(json['is_read'] ?? json['read']);
    final bool isAttended = _parseBool(json['is_attended'] ?? json['attended']);

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

    return ClientRequestModel(
      id: (json['id'] ?? '').toString(),
      loungeId: (json['lounge_id'] ?? json['loungeId'] ?? '').toString(),
      bookingId: (json['booking_id'] ?? metadataObj.bookingId)?.toString(),
      userId: (json['user_id'] ?? json['userId'])?.toString(),
      userName: (json['user_name'] ?? json['userName'] ?? json['full_name'])?.toString(),
      userPhone: (json['user_phone'] ?? json['userPhone'] ?? json['phone'])?.toString(),
      roomId: (json['room_id'] ?? metadataObj.roomId)?.toString(),
      roomName: (json['room_name'] ?? metadataObj.roomName)?.toString(),
      titleAr: (json['title_ar'] ?? json['title'] ?? 'طلب جديد').toString(),
      titleEn: (json['title_en'] ?? json['title'] ?? 'New Request').toString(),
      bodyAr: bodyAr,
      bodyEn: (json['body_en'] ?? json['body'] ?? 'Client request').toString(),
      type: type,
      isRead: isRead,
      isAttended: isAttended,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
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

    List<Map<String, dynamic>> parsedItems = [];
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .whereType<Map>()
          .map((i) => Map<String, dynamic>.from(i))
          .toList();
    }

    final String statusStr = (json['status'] ?? 'pending').toString().toLowerCase();
    final bool isAttended = statusStr == 'completed' || statusStr == 'attended' || _parseBool(json['is_attended']);

    final String roomName = (json['room_name'] ?? json['room'] ?? 'Gaming Station').toString();
    final String userName = (json['user_name'] ?? json['user'] ?? 'Client').toString();

    return ClientRequestModel(
      id: (json['id'] ?? '').toString(),
      loungeId: (json['lounge_id'] ?? '').toString(),
      bookingId: json['booking_id']?.toString(),
      userId: json['user_id']?.toString(),
      userName: userName,
      userPhone: json['user_phone']?.toString(),
      roomId: json['room_id']?.toString(),
      roomName: roomName,
      titleAr: 'طلب كافيتريا ($roomName)',
      titleEn: 'Canteen Order ($roomName)',
      bodyAr: 'العميل $userName طلب أصناف من المنيو',
      bodyEn: 'Client $userName ordered menu items',
      type: ClientRequestType.canteenOrder,
      isRead: isAttended,
      isAttended: isAttended,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      metadata: NotificationMetadata(
        bookingId: json['booking_id']?.toString(),
        roomId: json['room_id']?.toString(),
        roomName: roomName,
        notes: json['notes']?.toString(),
        items: parsedItems,
      ),
      canteenItems: parsedItems,
      totalPrice: parseDouble(json['total_price'] ?? json['price']),
    );
  }

  factory ClientRequestModel.fromBookingExtensionJson(Map<String, dynamic> json) {
    final int requestedMinutes = _parseInt(json['requested_minutes'] ?? json['extension_minutes'], 30);
    final int currentDuration = _parseInt(json['duration_minutes'], 60);
    final String roomName = (json['room_name'] ?? json['room'] ?? 'Station').toString();
    final String userName = (json['user_name'] ?? json['user'] ?? 'Client').toString();
    final String extStatus = (json['extension_status'] ?? 'pending').toString().toLowerCase();
    final bool isAttended = extStatus != 'pending';

    return ClientRequestModel(
      id: 'ext_${json['id']}',
      loungeId: (json['lounge_id'] ?? '').toString(),
      bookingId: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      userName: userName,
      userPhone: json['user_phone']?.toString(),
      roomId: json['room_id']?.toString(),
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
        roomId: json['room_id']?.toString(),
        roomName: roomName,
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
}
