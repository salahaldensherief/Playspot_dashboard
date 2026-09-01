import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/promo_entity.dart';
import '../entities/notification_entity.dart';

abstract class MarketingRepository {
  Future<Either<Failure, List<PromoEntity>>> getPromotions({String? loungeId, String? city});
  Future<Either<Failure, void>> createPromotion(PromoEntity promo);
  Future<Either<Failure, void>> deletePromotion(String id);

  // Notifications
  Future<Either<Failure, void>> sendNotification(NotificationEntity notification);
  Future<Either<Failure, List<NotificationEntity>>> getNotifications();
}
