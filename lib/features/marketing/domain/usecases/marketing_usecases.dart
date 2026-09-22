import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../../../../core/utils/paginated_result.dart';
import '../entities/notification_entity.dart';
import '../entities/promo_entity.dart';
import '../repositories/marketing_repository.dart';

class GetPromotionsParams extends Equatable {
  final String? loungeId;
  final String? city;

  const GetPromotionsParams({this.loungeId, this.city});

  @override
  List<Object?> get props => [loungeId, city];
}

class GetPromotionsUseCase implements UseCase<List<PromoEntity>, GetPromotionsParams> {
  final MarketingRepository repository;

  GetPromotionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PromoEntity>>> call(GetPromotionsParams params) {
    return repository.getPromotions(loungeId: params.loungeId, city: params.city);
  }
}

class CreatePromotionUseCase implements UseCase<void, PromoEntity> {
  final MarketingRepository repository;

  CreatePromotionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(PromoEntity promo) {
    return repository.createPromotion(promo);
  }
}

class UpdatePromotionUseCase implements UseCase<void, PromoEntity> {
  final MarketingRepository repository;

  UpdatePromotionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(PromoEntity promo) {
    return repository.updatePromotion(promo);
  }
}

class DeletePromotionUseCase implements UseCase<void, String> {
  final MarketingRepository repository;

  DeletePromotionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deletePromotion(id);
  }
}

class UploadPromoPosterParams extends Equatable {
  final Uint8List fileBytes;
  final String fileName;

  const UploadPromoPosterParams({required this.fileBytes, required this.fileName});

  @override
  List<Object?> get props => [fileBytes, fileName];
}

class UploadPromoPosterUseCase implements UseCase<String, UploadPromoPosterParams> {
  final MarketingRepository repository;

  UploadPromoPosterUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(UploadPromoPosterParams params) {
    return repository.uploadPromoPoster(params.fileBytes, params.fileName);
  }
}

class GetNotificationsUseCase implements UseCase<List<NotificationEntity>, NoParams> {
  final MarketingRepository repository;

  GetNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<NotificationEntity>>> call(NoParams params) {
    return repository.getNotifications();
  }
}

class GetNotificationsPageParams extends Equatable {
  final int page;
  final int pageSize;

  const GetNotificationsPageParams({this.page = 1, this.pageSize = 20});

  @override
  List<Object?> get props => [page, pageSize];
}

class GetNotificationsPageUseCase
    implements UseCase<PaginatedResult<NotificationEntity>, GetNotificationsPageParams> {
  final MarketingRepository repository;

  GetNotificationsPageUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<NotificationEntity>>> call(GetNotificationsPageParams params) {
    return repository.getNotificationsPage(page: params.page, pageSize: params.pageSize);
  }
}

class SendNotificationUseCase implements UseCase<void, NotificationEntity> {
  final MarketingRepository repository;

  SendNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NotificationEntity notification) {
    return repository.sendNotification(notification);
  }
}
