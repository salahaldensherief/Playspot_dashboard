import 'package:equatable/equatable.dart';
import 'notification_metadata.dart';

enum ClientRequestType {
  callStaff,
  canteenOrder,
  extendSession,
  serviceRequest,
  other,
}

/// Pure domain entity representing live client requests and alerts on the admin dashboard.
class ClientRequestEntity extends Equatable {
  final String id;
  final String loungeId;
  final String? bookingId;
  final String? userId;
  final String? userName;
  final String? userPhone;
  final String? roomId;
  final String? roomName;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final ClientRequestType type;
  final bool isRead;
  final bool isAttended;
  final DateTime createdAt;
  final NotificationMetadata metadata;
  final List<Map<String, dynamic>> canteenItems;
  final double? totalPrice;

  const ClientRequestEntity({
    required this.id,
    required this.loungeId,
    this.bookingId,
    this.userId,
    this.userName,
    this.userPhone,
    this.roomId,
    this.roomName,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.type,
    this.isRead = false,
    this.isAttended = false,
    required this.createdAt,
    this.metadata = const NotificationMetadata(),
    this.canteenItems = const [],
    this.totalPrice,
  });

  bool get isCanteenOrder => type == ClientRequestType.canteenOrder;

  ClientRequestEntity copyWith({
    String? id,
    String? loungeId,
    String? bookingId,
    String? userId,
    String? userName,
    String? userPhone,
    String? roomId,
    String? roomName,
    String? titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
    ClientRequestType? type,
    bool? isRead,
    bool? isAttended,
    DateTime? createdAt,
    NotificationMetadata? metadata,
    List<Map<String, dynamic>>? canteenItems,
    double? totalPrice,
  }) {
    return ClientRequestEntity(
      id: id ?? this.id,
      loungeId: loungeId ?? this.loungeId,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      bodyAr: bodyAr ?? this.bodyAr,
      bodyEn: bodyEn ?? this.bodyEn,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      isAttended: isAttended ?? this.isAttended,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      canteenItems: canteenItems ?? this.canteenItems,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  List<Object?> get props => [
        id,
        loungeId,
        bookingId,
        userId,
        userName,
        userPhone,
        roomId,
        roomName,
        titleAr,
        titleEn,
        bodyAr,
        bodyEn,
        type,
        isRead,
        isAttended,
        createdAt,
        metadata,
        canteenItems,
        totalPrice,
      ];
}
