import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/pricing_quote_entity.dart';
import '../../domain/entities/pricing_rule_entity.dart';
import '../../domain/repositories/pricing_repository.dart';
import '../datasources/pricing_remote_datasource.dart';
import '../models/pricing_rule_model.dart';

class PricingRepositoryImpl implements PricingRepository {
  final PricingRemoteDataSource remoteDataSource;

  PricingRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<PricingRuleEntity>>> getPricingRules({
    required String loungeId,
  }) async {
    try {
      final rules = await remoteDataSource.getPricingRules(loungeId: loungeId);
      return Right(rules);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PricingRuleEntity>> savePricingRule(
    PricingRuleEntity rule,
  ) async {
    try {
      final model = PricingRuleModel(
        id: rule.id,
        loungeId: rule.loungeId,
        spaceTypeId: rule.spaceTypeId,
        roomId: rule.roomId,
        nameAr: rule.nameAr,
        nameEn: rule.nameEn,
        ruleType: rule.ruleType,
        daysOfWeek: rule.daysOfWeek,
        startTime: rule.startTime,
        endTime: rule.endTime,
        startDate: rule.startDate,
        endDate: rule.endDate,
        adjustmentType: rule.adjustmentType,
        adjustmentValue: rule.adjustmentValue,
        isActive: rule.isActive,
        priority: rule.priority,
        createdAt: rule.createdAt,
      );
      final saved = await remoteDataSource.savePricingRule(model);
      return Right(saved);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePricingRule(String id) async {
    try {
      await remoteDataSource.deletePricingRule(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PricingRuleEntity>>> checkRuleConflicts(
    PricingRuleEntity rule,
  ) async {
    try {
      final model = PricingRuleModel(
        id: rule.id,
        loungeId: rule.loungeId,
        spaceTypeId: rule.spaceTypeId,
        roomId: rule.roomId,
        nameAr: rule.nameAr,
        nameEn: rule.nameEn,
        ruleType: rule.ruleType,
        daysOfWeek: rule.daysOfWeek,
        startTime: rule.startTime,
        endTime: rule.endTime,
        startDate: rule.startDate,
        endDate: rule.endDate,
        adjustmentType: rule.adjustmentType,
        adjustmentValue: rule.adjustmentValue,
        isActive: rule.isActive,
        priority: rule.priority,
        createdAt: rule.createdAt,
      );
      final conflicts = await remoteDataSource.checkRuleConflicts(model);
      return Right(conflicts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PricingQuoteEntity>> quoteBookingPrice({
    required String roomId,
    required String date,
    required String startTime,
    required String endTime,
    String playMode = 'single',
    int extraControllers = 0,
    String? couponCode,
  }) async {
    try {
      final quote = await remoteDataSource.quoteBookingPrice(
        roomId: roomId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        playMode: playMode,
        extraControllers: extraControllers,
        couponCode: couponCode,
      );
      return Right(quote);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getRoomSlotsWithPrices({
    required String roomId,
    required String date,
  }) async {
    try {
      final slots = await remoteDataSource.getRoomSlotsWithPrices(
        roomId: roomId,
        date: date,
      );
      return Right(slots);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getLoungePriceRange({
    required String loungeId,
  }) async {
    try {
      final range = await remoteDataSource.getLoungePriceRange(loungeId: loungeId);
      return Right(range);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
