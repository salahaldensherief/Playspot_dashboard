import 'package:equatable/equatable.dart';
import '../../domain/entities/promo_entity.dart';
import '../../domain/entities/notification_entity.dart';

enum MarketingStatus { initial, loading, success, actionSuccess, failure }

class MarketingState extends Equatable {
  final MarketingStatus status;
  final List<PromoEntity> promotions;
  final List<NotificationEntity> notifications;
  final String? errorMessage;

  const MarketingState({
    this.status = MarketingStatus.initial,
    this.promotions = const [],
    this.notifications = const [],
    this.errorMessage,
  });

  MarketingState copyWith({
    MarketingStatus? status,
    List<PromoEntity>? promotions,
    List<NotificationEntity>? notifications,
    String? errorMessage,
  }) {
    return MarketingState(
      status: status ?? this.status,
      promotions: promotions ?? this.promotions,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, promotions, notifications, errorMessage];
}
