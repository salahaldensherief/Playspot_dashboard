import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../../../../core/utils/paginated_result.dart';
import '../../data/models/loyalty_stats_model.dart';
import '../entities/loyalty_level_entity.dart';
import '../entities/loyalty_task_entity.dart';
import '../entities/points_transaction_entity.dart';
import '../entities/referral_entity.dart';
import '../../../marketing/domain/entities/redemption_option_entity.dart';
import '../repositories/loyalty_repository.dart';

class GetLoyaltyStatsParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? levelId;
  final String? referralStatus;
  final String? userId;

  const GetLoyaltyStatsParams({
    this.startDate,
    this.endDate,
    this.levelId,
    this.referralStatus,
    this.userId,
  });

  @override
  List<Object?> get props => [startDate, endDate, levelId, referralStatus, userId];
}

class GetLoyaltyStatsUseCase implements UseCase<LoyaltyStatsModel, GetLoyaltyStatsParams> {
  final LoyaltyRepository repository;

  GetLoyaltyStatsUseCase(this.repository);

  @override
  Future<Either<Failure, LoyaltyStatsModel>> call(GetLoyaltyStatsParams params) {
    return repository.getLoyaltyStats(
      startDate: params.startDate,
      endDate: params.endDate,
      levelId: params.levelId,
      referralStatus: params.referralStatus,
      userId: params.userId,
    );
  }
}

class GetReferralsParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final String? userId;

  const GetReferralsParams({
    this.startDate,
    this.endDate,
    this.status,
    this.userId,
  });

  @override
  List<Object?> get props => [startDate, endDate, status, userId];
}

class GetReferralsUseCase implements UseCase<List<ReferralEntity>, GetReferralsParams> {
  final LoyaltyRepository repository;

  GetReferralsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ReferralEntity>>> call(GetReferralsParams params) {
    return repository.getReferrals(
      startDate: params.startDate,
      endDate: params.endDate,
      status: params.status,
      userId: params.userId,
    );
  }
}

class GetLoyaltyTasksUseCase implements UseCase<List<LoyaltyTaskEntity>, NoParams> {
  final LoyaltyRepository repository;

  GetLoyaltyTasksUseCase(this.repository);

  @override
  Future<Either<Failure, List<LoyaltyTaskEntity>>> call(NoParams params) {
    return repository.getTasks();
  }
}

class UpdateLoyaltyTaskParams extends Equatable {
  final String id;
  final Map<String, dynamic> data;

  const UpdateLoyaltyTaskParams({required this.id, required this.data});

  @override
  List<Object?> get props => [id, data];
}

class UpdateLoyaltyTaskUseCase implements UseCase<void, UpdateLoyaltyTaskParams> {
  final LoyaltyRepository repository;

  UpdateLoyaltyTaskUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateLoyaltyTaskParams params) {
    return repository.updateTask(params.id, params.data);
  }
}

class GetLoyaltyLevelsUseCase implements UseCase<List<LoyaltyLevelEntity>, NoParams> {
  final LoyaltyRepository repository;

  GetLoyaltyLevelsUseCase(this.repository);

  @override
  Future<Either<Failure, List<LoyaltyLevelEntity>>> call(NoParams params) {
    return repository.getLevels();
  }
}

class UpdateLoyaltyLevelParams extends Equatable {
  final String id;
  final Map<String, dynamic> data;

  const UpdateLoyaltyLevelParams({required this.id, required this.data});

  @override
  List<Object?> get props => [id, data];
}

class UpdateLoyaltyLevelUseCase implements UseCase<void, UpdateLoyaltyLevelParams> {
  final LoyaltyRepository repository;

  UpdateLoyaltyLevelUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateLoyaltyLevelParams params) {
    return repository.updateLevel(params.id, params.data);
  }
}

class AdjustUserPointsParams extends Equatable {
  final String userId;
  final int pointsDelta;
  final String reason;

  const AdjustUserPointsParams({
    required this.userId,
    required this.pointsDelta,
    required this.reason,
  });

  @override
  List<Object?> get props => [userId, pointsDelta, reason];
}

class AdjustUserPointsUseCase implements UseCase<void, AdjustUserPointsParams> {
  final LoyaltyRepository repository;

  AdjustUserPointsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AdjustUserPointsParams params) {
    return repository.adjustUserPoints(
      userId: params.userId,
      pointsDelta: params.pointsDelta,
      reason: params.reason,
    );
  }
}

class GetPointsTransactionsPageParams extends Equatable {
  final int page;
  final int pageSize;

  const GetPointsTransactionsPageParams({this.page = 1, this.pageSize = 20});

  @override
  List<Object?> get props => [page, pageSize];
}

class GetPointsTransactionsPageUseCase
    implements UseCase<PaginatedResult<PointsTransactionEntity>, GetPointsTransactionsPageParams> {
  final LoyaltyRepository repository;

  GetPointsTransactionsPageUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<PointsTransactionEntity>>> call(
      GetPointsTransactionsPageParams params) {
    return repository.getPointsTransactionsPage(
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}

class GetRedemptionOptionsUseCase implements UseCase<List<RedemptionOptionEntity>, NoParams> {
  final LoyaltyRepository repository;

  GetRedemptionOptionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<RedemptionOptionEntity>>> call(NoParams params) {
    return repository.getRedemptionOptions();
  }
}

class CreateRedemptionOptionUseCase implements UseCase<void, RedemptionOptionEntity> {
  final LoyaltyRepository repository;

  CreateRedemptionOptionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RedemptionOptionEntity option) {
    return repository.createRedemptionOption(option);
  }
}

class UpdateRedemptionOptionParams extends Equatable {
  final String id;
  final Map<String, dynamic> data;

  const UpdateRedemptionOptionParams({required this.id, required this.data});

  @override
  List<Object?> get props => [id, data];
}

class UpdateRedemptionOptionUseCase implements UseCase<void, UpdateRedemptionOptionParams> {
  final LoyaltyRepository repository;

  UpdateRedemptionOptionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateRedemptionOptionParams params) {
    return repository.updateRedemptionOption(params.id, params.data);
  }
}

class DeleteRedemptionOptionUseCase implements UseCase<void, String> {
  final LoyaltyRepository repository;

  DeleteRedemptionOptionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deleteRedemptionOption(id);
  }
}
