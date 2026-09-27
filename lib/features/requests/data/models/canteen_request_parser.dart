import '../../domain/entities/client_request_entity.dart';
import '../../domain/entities/notification_metadata.dart';
import 'canteen_item_extractor.dart';
import 'client_request_model.dart';
import 'client_request_parser.dart';

class CanteenRequestParser {
  static ClientRequestModel parse(Map<String, dynamic> json) {
    final metadataObj = NotificationMetadata.fromJson(json['metadata']);
    List<Map<String, dynamic>> parsedItems = CanteenItemExtractor.extract(json);

    if (parsedItems.isEmpty && metadataObj.items.isNotEmpty) {
      parsedItems = metadataObj.items;
    }

    final String statusStr = (json['status'] ?? 'pending').toString().toLowerCase();
    final bool isAttended = statusStr == 'completed' ||
        statusStr == 'attended' ||
        statusStr == 'approved' ||
        statusStr == 'resolved' ||
        ClientRequestParser.parseBool(json['is_attended']) ||
        ClientRequestParser.parseBool(json['attended']);

    final bookingObj = ClientRequestParser.parseMap(json['bookings']);
    final String roomName = (json['room_name'] ??
            json['roomName'] ??
            json['room'] ??
            bookingObj?['room_name'] ??
            metadataObj.roomName ??
            '')
        .toString();
    final String userName = (json['user_name'] ??
            json['userName'] ??
            json['user'] ??
            json['full_name'] ??
            bookingObj?['user_name'] ??
            metadataObj.userName ??
            '')
        .toString();
    final userPhone = (json['user_phone'] ??
            json['userPhone'] ??
            json['phone'] ??
            bookingObj?['user_phone'] ??
            metadataObj.userPhone ??
            '')
        .toString();
    final userAvatarUrl = (json['user_avatar'] ??
            json['user_avatar_url'] ??
            json['avatar_url'] ??
            bookingObj?['avatar_url'] ??
            metadataObj.userAvatar)
        ?.toString();

    final String reqId = (json['id'] ?? '').toString();

    return ClientRequestModel(
      id: reqId,
      loungeId: (json['lounge_id'] ?? json['loungeId'] ?? bookingObj?['lounge_id'] ?? metadataObj.loungeId ?? '')
          .toString(),
      bookingId: (json['booking_id'] ?? json['bookingId'] ?? bookingObj?['id'] ?? metadataObj.bookingId)?.toString(),
      userId: (json['user_id'] ?? json['userId'] ?? bookingObj?['user_id'] ?? metadataObj.userId)?.toString(),
      userName: userName,
      userPhone: userPhone,
      userAvatarUrl: userAvatarUrl,
      roomId: (json['room_id'] ?? json['roomId'] ?? bookingObj?['room_id'] ?? metadataObj.roomId)?.toString(),
      roomName: roomName,
      titleAr: 'طلب كافيتريا ($roomName)',
      titleEn: 'Canteen Order ($roomName)',
      bodyAr: parsedItems.isNotEmpty
          ? 'العميل $userName طلب أصناف من المنيو (${parsedItems.length} صنف)'
          : 'العميل $userName طلب أصناف من المنيو',
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
      totalPrice: ClientRequestParser.parseDouble(json['total_price'] ?? json['price'] ?? json['amount']),
    );
  }
}
