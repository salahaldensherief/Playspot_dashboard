import '../models/canteen_combo_model.dart';
import '../models/low_stock_alert_model.dart';
import '../models/upsell_conversion_model.dart';
import '../models/upsell_rule_model.dart';

abstract class CanteenRemoteDataSource {
  Future<List<CanteenComboModel>> getCombos({required String loungeId});

  Future<CanteenComboModel> saveCombo(CanteenComboModel combo);

  Future<void> deleteCombo(String id);

  Future<List<UpsellRuleModel>> getUpsellRules({required String loungeId});

  Future<UpsellRuleModel> saveUpsellRule(UpsellRuleModel rule);

  Future<void> deleteUpsellRule(String id);

  Future<List<UpsellConversionModel>> getUpsellConversions({required String loungeId});

  Future<List<LowStockAlertModel>> getLowStockAlerts({required String loungeId});
}
