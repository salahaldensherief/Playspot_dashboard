import 'package:equatable/equatable.dart';
import '../domain/entities/canteen_combo_entity.dart';
import '../domain/entities/low_stock_alert_entity.dart';
import '../domain/entities/upsell_conversion_entity.dart';
import '../domain/entities/upsell_rule_entity.dart';

enum CanteenStatus { initial, loading, success, failure }

class CanteenState extends Equatable {
  final CanteenStatus status;
  final List<CanteenComboEntity> combos;
  final List<UpsellRuleEntity> upsellRules;
  final List<UpsellConversionEntity> conversions;
  final List<LowStockAlertEntity> lowStockAlerts;
  final String? errorMessage;
  final bool isSaving;

  const CanteenState({
    this.status = CanteenStatus.initial,
    this.combos = const [],
    this.upsellRules = const [],
    this.conversions = const [],
    this.lowStockAlerts = const [],
    this.errorMessage,
    this.isSaving = false,
  });

  UpsellConversionEntity? getConversionForRule(String ruleId) {
    try {
      return conversions.firstWhere((c) => c.ruleId == ruleId);
    } catch (_) {
      return null;
    }
  }

  CanteenState copyWith({
    CanteenStatus? status,
    List<CanteenComboEntity>? combos,
    List<UpsellRuleEntity>? upsellRules,
    List<UpsellConversionEntity>? conversions,
    List<LowStockAlertEntity>? lowStockAlerts,
    String? errorMessage,
    bool? isSaving,
  }) {
    return CanteenState(
      status: status ?? this.status,
      combos: combos ?? this.combos,
      upsellRules: upsellRules ?? this.upsellRules,
      conversions: conversions ?? this.conversions,
      lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
      errorMessage: errorMessage,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [
        status,
        combos,
        upsellRules,
        conversions,
        lowStockAlerts,
        errorMessage,
        isSaving,
      ];
}
