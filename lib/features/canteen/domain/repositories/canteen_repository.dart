import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/canteen_combo_entity.dart';
import '../entities/low_stock_alert_entity.dart';
import '../entities/upsell_conversion_entity.dart';
import '../entities/upsell_rule_entity.dart';

abstract class CanteenRepository {
  Future<Either<Failure, List<CanteenComboEntity>>> getCombos({
    required String loungeId,
    bool forceRefresh = false,
  });

  Future<Either<Failure, CanteenComboEntity>> saveCombo(
    CanteenComboEntity combo,
  );

  Future<Either<Failure, void>> deleteCombo(String id);

  Future<Either<Failure, List<UpsellRuleEntity>>> getUpsellRules({
    required String loungeId,
    bool forceRefresh = false,
  });

  Future<Either<Failure, UpsellRuleEntity>> saveUpsellRule(
    UpsellRuleEntity rule,
  );

  Future<Either<Failure, void>> deleteUpsellRule(String id);

  Future<Either<Failure, List<UpsellConversionEntity>>> getUpsellConversions({
    required String loungeId,
  });

  Future<Either<Failure, List<LowStockAlertEntity>>> getLowStockAlerts({
    required String loungeId,
  });
}
