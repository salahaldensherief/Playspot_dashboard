import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../datasources/loyalty_remote_data_source.dart';
import '../models/loyalty_stats_model.dart';
import '../../domain/entities/referral_entity.dart';
import '../../domain/entities/loyalty_task_entity.dart';
import '../../domain/entities/loyalty_level_entity.dart';
import '../../../marketing/domain/entities/redemption_option_entity.dart';
import '../../../marketing/data/models/redemption_option_model.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  final LoyaltyRemoteDataSource remoteDataSource;
  LoyaltyRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, LoyaltyStatsModel>> getLoyaltyStats({
    DateTime? startDate,
    DateTime? endDate,
    String? levelId,
    String? referralStatus,
    String? userId,
  }) async {
    try {
      final stats = await remoteDataSource.getLoyaltyStats(
        startDate: startDate,
        endDate: endDate,
        levelId: levelId,
        referralStatus: referralStatus,
        userId: userId,
      );
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReferralEntity>>> getReferrals({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? userId,
  }) async {
    try {
      final referrals = await remoteDataSource.getReferrals(
        startDate: startDate,
        endDate: endDate,
        status: status,
        userId: userId,
      );
      return Right(referrals);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LoyaltyTaskEntity>>> getTasks() async {
    try {
      final tasks = await remoteDataSource.getTasks();
      return Right(tasks);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTask(String id, Map<String, dynamic> data) async {
    try {
      await remoteDataSource.updateTask(id, data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LoyaltyLevelEntity>>> getLevels() async {
    try {
      final levels = await remoteDataSource.getLevels();
      return Right(levels);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLevel(String id, Map<String, dynamic> data) async {
    try {
      await remoteDataSource.updateLevel(id, data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> adjustUserPoints({
    required String userId,
    required int pointsDelta,
    required String reason,
  }) async {
    try {
      await remoteDataSource.adjustUserPoints(
        userId: userId,
        pointsDelta: pointsDelta,
        reason: reason,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RedemptionOptionEntity>>> getRedemptionOptions() async {
    try {
      final options = await remoteDataSource.getRedemptionOptions();
      return Right(options);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createRedemptionOption(RedemptionOptionEntity option) async {
    try {
      await remoteDataSource.createRedemptionOption(RedemptionOptionModel(
        id: option.id,
        titleAr: option.titleAr,
        titleEn: option.titleEn,
        descriptionAr: option.descriptionAr,
        descriptionEn: option.descriptionEn,
        pointsCost: option.pointsCost,
        rewardType: option.rewardType,
        rewardValue: option.rewardValue,
        isActive: option.isActive,
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateRedemptionOption(String id, Map<String, dynamic> data) async {
    try {
      await remoteDataSource.updateRedemptionOption(id, data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRedemptionOption(String id) async {
    try {
      await remoteDataSource.deleteRedemptionOption(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
