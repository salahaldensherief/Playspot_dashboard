import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/promo_entity.dart';
import '../../domain/repositories/marketing_repository.dart';
import '../datasources/marketing_remote_data_source.dart';
import '../models/notification_model.dart';
import '../models/promo_model.dart';

class MarketingRepositoryImpl implements MarketingRepository {
  final MarketingRemoteDataSource remoteDataSource;

  MarketingRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<PromoEntity>>> getPromotions({String? loungeId}) async {
    try {
      final promos = await remoteDataSource.getPromotions(loungeId: loungeId);
      return Right(promos);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createPromotion(PromoEntity promo) async {
    try {
      await remoteDataSource.createPromotion(PromoModel(
        id: promo.id,
        titleAr: promo.titleAr,
        titleEn: promo.titleEn,
        tagAr: promo.tagAr,
        tagEn: promo.tagEn,
        hexColors: promo.hexColors,
        iconKey: promo.iconKey,
        imageUrl: promo.imageUrl,
        deepLink: promo.deepLink,
        loungeId: promo.loungeId,
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePromotion(String id) async {
    try {
      await remoteDataSource.deletePromotion(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendNotification(NotificationEntity notification) async {
    try {
      await remoteDataSource.sendNotification(NotificationModel(
        id: notification.id,
        userId: notification.userId,
        titleAr: notification.titleAr,
        titleEn: notification.titleEn,
        bodyAr: notification.bodyAr,
        bodyEn: notification.bodyEn,
        type: notification.type,
        createdAt: notification.createdAt,
        metadata: notification.metadata,
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications() async {
    try {
      final notifications = await remoteDataSource.getNotifications();
      return Right(notifications);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
