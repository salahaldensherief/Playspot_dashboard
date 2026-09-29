import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/entities/canteen_combo_entity.dart';
import '../domain/entities/upsell_rule_entity.dart';
import '../domain/usecases/delete_combo_usecase.dart';
import '../domain/usecases/delete_upsell_rule_usecase.dart';
import '../domain/usecases/get_combos_params.dart';
import '../domain/usecases/get_combos_usecase.dart';
import '../domain/usecases/get_low_stock_alerts_usecase.dart';
import '../domain/usecases/get_upsell_conversions_usecase.dart';
import '../domain/usecases/get_upsell_rules_params.dart';
import '../domain/usecases/get_upsell_rules_usecase.dart';
import '../domain/usecases/save_combo_usecase.dart';
import '../domain/usecases/save_upsell_rule_usecase.dart';
import 'canteen_state.dart';

class CanteenCubit extends Cubit<CanteenState> {
  final GetCombosUseCase getCombosUseCase;
  final SaveComboUseCase saveComboUseCase;
  final DeleteComboUseCase deleteComboUseCase;
  final GetUpsellRulesUseCase getUpsellRulesUseCase;
  final SaveUpsellRuleUseCase saveUpsellRuleUseCase;
  final DeleteUpsellRuleUseCase deleteUpsellRuleUseCase;
  final GetUpsellConversionsUseCase getUpsellConversionsUseCase;
  final GetLowStockAlertsUseCase getLowStockAlertsUseCase;

  String? _currentLoungeId;

  CanteenCubit({
    required this.getCombosUseCase,
    required this.saveComboUseCase,
    required this.deleteComboUseCase,
    required this.getUpsellRulesUseCase,
    required this.saveUpsellRuleUseCase,
    required this.deleteUpsellRuleUseCase,
    required this.getUpsellConversionsUseCase,
    required this.getLowStockAlertsUseCase,
  }) : super(const CanteenState());

  String? get currentLoungeId => _currentLoungeId;

  Future<void> loadAll(String loungeId, {bool forceRefresh = false}) async {
    _currentLoungeId = loungeId;
    emit(state.copyWith(status: CanteenStatus.loading));

    final combosRes = await getCombosUseCase(
      GetCombosParams(loungeId: loungeId, forceRefresh: forceRefresh),
    );
    final rulesRes = await getUpsellRulesUseCase(
      GetUpsellRulesParams(loungeId: loungeId, forceRefresh: forceRefresh),
    );
    final convRes = await getUpsellConversionsUseCase(loungeId);
    final alertsRes = await getLowStockAlertsUseCase(loungeId);

    if (isClosed) return;

    combosRes.fold(
      (failure) => emit(state.copyWith(
        status: CanteenStatus.failure,
        errorMessage: failure.message,
      )),
      (combos) {
        rulesRes.fold(
          (failure) => emit(state.copyWith(
            status: CanteenStatus.failure,
            errorMessage: failure.message,
          )),
          (rules) {
            final convList = convRes.getOrElse(() => []);
            final alertsList = alertsRes.getOrElse(() => []);

            emit(state.copyWith(
              status: CanteenStatus.success,
              combos: combos,
              upsellRules: rules,
              conversions: convList,
              lowStockAlerts: alertsList,
            ));
          },
        );
      },
    );
  }

  Future<bool> saveCombo(CanteenComboEntity combo) async {
    emit(state.copyWith(isSaving: true));
    final res = await saveComboUseCase(combo);
    if (isClosed) return false;

    return res.fold(
      (failure) {
        emit(state.copyWith(isSaving: false, errorMessage: failure.message));
        return false;
      },
      (savedCombo) {
        final currentCombos = List<CanteenComboEntity>.from(state.combos);
        final index = currentCombos.indexWhere((c) => c.id == savedCombo.id);
        if (index != -1) {
          currentCombos[index] = savedCombo;
        } else {
          currentCombos.insert(0, savedCombo);
        }
        emit(state.copyWith(isSaving: false, combos: currentCombos));
        return true;
      },
    );
  }

  Future<void> toggleComboActive(CanteenComboEntity combo) async {
    final updated = CanteenComboEntity(
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
      isActive: !combo.isActive,
      sortOrder: combo.sortOrder,
      items: combo.items,
    );
    await saveCombo(updated);
  }

  Future<bool> deleteCombo(String id) async {
    final res = await deleteComboUseCase(id);
    if (isClosed) return false;

    return res.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
      (_) {
        final currentCombos = state.combos.where((c) => c.id != id).toList();
        emit(state.copyWith(combos: currentCombos));
        return true;
      },
    );
  }

  Future<bool> saveUpsellRule(UpsellRuleEntity rule) async {
    emit(state.copyWith(isSaving: true));
    final res = await saveUpsellRuleUseCase(rule);
    if (isClosed) return false;

    return res.fold(
      (failure) {
        emit(state.copyWith(isSaving: false, errorMessage: failure.message));
        return false;
      },
      (savedRule) {
        final currentRules = List<UpsellRuleEntity>.from(state.upsellRules);
        final index = currentRules.indexWhere((r) => r.id == savedRule.id);
        if (index != -1) {
          currentRules[index] = savedRule;
        } else {
          currentRules.insert(0, savedRule);
        }
        emit(state.copyWith(isSaving: false, upsellRules: currentRules));
        return true;
      },
    );
  }

  Future<void> toggleUpsellRuleActive(UpsellRuleEntity rule) async {
    final updated = UpsellRuleEntity(
      id: rule.id,
      loungeId: rule.loungeId,
      triggerType: rule.triggerType,
      triggerParams: rule.triggerParams,
      suggestExtraId: rule.suggestExtraId,
      suggestComboId: rule.suggestComboId,
      discountPercent: rule.discountPercent,
      maxImpressionsPerBooking: rule.maxImpressionsPerBooking,
      priority: rule.priority,
      isActive: !rule.isActive,
      createdAt: rule.createdAt,
      suggestedNameAr: rule.suggestedNameAr,
      suggestedNameEn: rule.suggestedNameEn,
      suggestedPrice: rule.suggestedPrice,
      suggestedImageUrl: rule.suggestedImageUrl,
      isCombo: rule.isCombo,
    );
    await saveUpsellRule(updated);
  }

  Future<bool> deleteUpsellRule(String id) async {
    final res = await deleteUpsellRuleUseCase(id);
    if (isClosed) return false;

    return res.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
      (_) {
        final currentRules = state.upsellRules.where((r) => r.id != id).toList();
        emit(state.copyWith(upsellRules: currentRules));
        return true;
      },
    );
  }
}
