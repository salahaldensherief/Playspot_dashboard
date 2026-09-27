import '../../domain/entities/client_request_entity.dart';
import '../../domain/entities/notification_metadata.dart';
import 'client_request_parser.dart';

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

  factory ClientRequestModel.fromNotificationJson(Map<String, dynamic> json) {
    return ClientRequestParser.parseNotification(json);
  }

  factory ClientRequestModel.fromCanteenOrderJson(Map<String, dynamic> json) {
    return ClientRequestParser.parseCanteenOrder(json);
  }

  factory ClientRequestModel.fromBookingExtensionJson(Map<String, dynamic> json) {
    return ClientRequestParser.parseBookingExtension(json);
  }

  factory ClientRequestModel.fromServiceCallJson(
    Map<String, dynamic> json, {
    Map<String, String>? roomNamesMap,
    Map<String, String>? userNamesMap,
    Map<String, String>? userAvatarsMap,
  }) {
    return ClientRequestParser.parseServiceCall(
      json,
      roomNamesMap: roomNamesMap,
      userNamesMap: userNamesMap,
      userAvatarsMap: userAvatarsMap,
    );
  }

  factory ClientRequestModel.fromBookingItemJson(Map<String, dynamic> json) {
    return ClientRequestParser.parseBookingItem(json);
  }
}