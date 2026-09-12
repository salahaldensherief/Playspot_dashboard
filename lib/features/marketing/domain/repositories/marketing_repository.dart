import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../../../../core/utils/paginated_result.dart';
import '../entities/promo_entity.dart';
import '../entities/notification_entity.dart';

abstract class MarketingRepository {
  Future<Either<Failure, List<PromoEntity>>> getPromotions({String? loungeId, String? city});
  Future<Either<Failure, void>> createPromotion(PromoEntity promo);
  Future<Either<Failure, void>> deletePromotion(String id);
  Future<Either<Failure, String>> uploadPromoPoster(Uint8List fileBytes, String fileName);

  // Notifications
  Future<Either<Failure, void>> sendNotification(NotificationEntity notification);
  Future<Either<Failure, List<NotificationEntity>>> getNotifications();
  Future<Either<Failure, List<NotificationEntity>>> getNotificationsRpc({String lang = 'ar', int limit = 20, int offset = 0});
  Future<Either<Failure, PaginatedResult<NotificationEntity>>> getNotificationsPage({int page = 1, int pageSize = 20});
  Future<Either<Failure, void>> markNotificationRead(String notificationId);
  Future<Either<Failure, void>> markAllNotificationsRead();
}
