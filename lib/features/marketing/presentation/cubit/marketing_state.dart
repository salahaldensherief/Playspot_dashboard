import 'package:equatable/equatable.dart';
import '../../domain/entities/promo_entity.dart';
import '../../domain/entities/notification_entity.dart';

enum MarketingStatus { initial, loading, success, actionSuccess, failure }

class MarketingState extends Equatable {
  final MarketingStatus status;
  final List<PromoEntity> promotions;
  final List<NotificationEntity> notifications;
  final int notificationPage;
  final int notificationPageSize;
  final int totalNotificationsCount;
  final String? errorMessage;

  const MarketingState({
    this.status = MarketingStatus.initial,
    this.promotions = const [],
    this.notifications = const [],
    this.notificationPage = 1,
    this.notificationPageSize = 20,
    this.totalNotificationsCount = 0,
    this.errorMessage,
  });

  bool get hasNextNotificationPage => notificationPage * notificationPageSize < totalNotificationsCount;
  bool get hasPreviousNotificationPage => notificationPage > 1;
  int get totalNotificationPages => notificationPageSize > 0 ? (totalNotificationsCount / notificationPageSize).ceil() : 0;

  MarketingState copyWith({
    MarketingStatus? status,
    List<PromoEntity>? promotions,
    List<NotificationEntity>? notifications,
    int? notificationPage,
    int? notificationPageSize,
    int? totalNotificationsCount,
    String? errorMessage,
  }) {
    return MarketingState(
      status: status ?? this.status,
      promotions: promotions ?? this.promotions,
      notifications: notifications ?? this.notifications,
      notificationPage: notificationPage ?? this.notificationPage,
      notificationPageSize: notificationPageSize ?? this.notificationPageSize,
      totalNotificationsCount: totalNotificationsCount ?? this.totalNotificationsCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        promotions,
        notifications,
        notificationPage,
        notificationPageSize,
        totalNotificationsCount,
        errorMessage,
      ];
}
