import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/canteen_combo_entity.dart';
import '../../domain/entities/low_stock_alert_entity.dart';
import '../../domain/entities/upsell_conversion_entity.dart';
import '../../domain/entities/upsell_rule_entity.dart';
import '../../domain/repositories/canteen_repository.dart';
import '../datasources/canteen_remote_datasource.dart';
import '../models/canteen_combo_component_model.dart';
import '../models/canteen_combo_model.dart';
import '../models/upsell_rule_model.dart';

class CanteenRepositoryImpl implements CanteenRepository {
  final CanteenRemoteDataSource remoteDataSource;

  CanteenRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<CanteenComboEntity>>> getCombos({
    required String loungeId,
    bool forceRefresh = false,
  }) async {
    try {
      final combos = await remoteDataSource.getCombos(loungeId: loungeId);
      return Right(combos);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CanteenComboEntity>> saveCombo(
    CanteenComboEntity combo,
  ) async {
    try {
      final itemsModel = combo.items.map((item) {
        return CanteenComboComponentModel(
          comboId: item.comboId,
          extraId: item.extraId,
          quantity: item.quantity,
          extraNameAr: item.extraNameAr,
          extraNameEn: item.extraNameEn,
          extraPrice: item.extraPrice,
          extraCostPrice: item.extraCostPrice,
          extraImageUrl: item.extraImageUrl,
        );
      }).toList();

      final model = CanteenComboModel(
        id: combo.id,
        loungeId: combo.loungeId,
        nameAr: combo.nameAr,
        nameEn: combo.nameEn,
        descriptionAr: combo.descriptionAr,
        descriptionEn: combo.descriptionEn,
        imageUrl: combo.imageUrl,
        price: combo.price,
        daysOfWeek: combo.daysOfWeek,
        availableFrom: combo.availableFrom,
        availableTo: combo.availableTo,
        validFrom: combo.validFrom,
        validTo: combo.validTo,
        isActive: combo.isActive,
        sortOrder: combo.sortOrder,
        items: itemsModel,
      );

      final saved = await remoteDataSource.saveCombo(model);
      return Right(saved);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCombo(String id) async {
    try {
      await remoteDataSource.deleteCombo(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UpsellRuleEntity>>> getUpsellRules({
    required String loungeId,
    bool forceRefresh = false,
  }) async {
    try {
      final rules = await remoteDataSource.getUpsellRules(loungeId: loungeId);
      return Right(rules);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UpsellRuleEntity>> saveUpsellRule(
    UpsellRuleEntity rule,
  ) async {
    try {
      final model = UpsellRuleModel(
        id: rule.id,
        loungeId: rule.loungeId,
        triggerType: rule.triggerType,
        triggerParams: rule.triggerParams,
        suggestExtraId: rule.suggestExtraId,
        suggestComboId: rule.suggestComboId,
        discountPercent: rule.discountPercent,
        maxImpressionsPerBooking: rule.maxImpressionsPerBooking,
        priority: rule.priority,
        isActive: rule.isActive,
      );

      final saved = await remoteDataSource.saveUpsellRule(model);
      return Right(saved);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUpsellRule(String id) async {
    try {
      await remoteDataSource.deleteUpsellRule(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UpsellConversionEntity>>> getUpsellConversions({
    required String loungeId,
  }) async {
    try {
      final conversions = await remoteDataSource.getUpsellConversions(loungeId: loungeId);
      return Right(conversions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LowStockAlertEntity>>> getLowStockAlerts({
    required String loungeId,
  }) async {
    try {
      final alerts = await remoteDataSource.getLowStockAlerts(loungeId: loungeId);
      return Right(alerts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
