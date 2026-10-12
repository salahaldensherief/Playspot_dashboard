import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../art_core/app_strings.dart';
import '../domain/entities/pricing_rule_entity.dart';
import '../domain/usecases/check_pricing_rule_conflicts_usecase.dart';
import '../domain/usecases/delete_pricing_rule_usecase.dart';
import '../domain/usecases/get_pricing_rules_usecase.dart';
import '../domain/usecases/quote_booking_price_usecase.dart';
import '../domain/usecases/save_pricing_rule_usecase.dart';
import 'pricing_state.dart';

class PricingCubit extends Cubit<PricingState> {
  final GetPricingRulesUseCase getPricingRulesUseCase;
  final SavePricingRuleUseCase savePricingRuleUseCase;
  final DeletePricingRuleUseCase deletePricingRuleUseCase;
  final CheckPricingRuleConflictsUseCase checkPricingRuleConflictsUseCase;
  final QuoteBookingPriceUseCase quoteBookingPriceUseCase;

  PricingCubit({
    required this.getPricingRulesUseCase,
    required this.savePricingRuleUseCase,
    required this.deletePricingRuleUseCase,
    required this.checkPricingRuleConflictsUseCase,
    required this.quoteBookingPriceUseCase,
  }) : super(const PricingState());

  int _loadGeneration = 0;
  int _quoteGeneration = 0;

  Future<void> loadPricingRules({required String loungeId}) async {
    if (isClosed) return;
    final generation = ++_loadGeneration;
    emit(state.copyWith(status: PricingStatus.loading));
    final result = await getPricingRulesUseCase(
      GetPricingRulesParams(loungeId: loungeId),
    );
    if (isClosed || generation != _loadGeneration) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PricingStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (rules) =>
          emit(state.copyWith(status: PricingStatus.success, rules: rules)),
    );
  }

  void changeGroupBy(PricingGroupBy groupBy) {
    if (isClosed) return;
    emit(state.copyWith(groupBy: groupBy));
  }

  Future<bool> saveRule(
    PricingRuleEntity rule, {
    required String loungeId,
  }) async {
    if (isClosed || state.isSaving) return false;
    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: null,
        conflictingRules: const [],
      ),
    );

    final conflictResult = await checkPricingRuleConflictsUseCase(
      CheckPricingRuleConflictsParams(rule: rule),
    );

    if (isClosed) return false;
    final conflicts = conflictResult.fold<List<PricingRuleEntity>>((failure) {
      emit(state.copyWith(isSaving: false, errorMessage: failure.message));
      return const [];
    }, (value) => value);

    if (state.errorMessage != null) return false;

    if (conflicts.isNotEmpty) {
      emit(state.copyWith(isSaving: false, conflictingRules: conflicts));
      return false;
    }

    final result = await savePricingRuleUseCase(
      SavePricingRuleParams(rule: rule),
    );
    if (isClosed) return false;
    return result.fold(
      (failure) {
        emit(state.copyWith(isSaving: false, errorMessage: failure.message));
        return false;
      },
      (savedRule) {
        emit(
          state.copyWith(
            isSaving: false,
            successMessage: AppStrings.pricingRuleSaved,
          ),
        );
        unawaited(loadPricingRules(loungeId: loungeId));
        return true;
      },
    );
  }

  Future<void> deleteRule(String id, {required String loungeId}) async {
    if (isClosed) return;
    final result = await deletePricingRuleUseCase(
      DeletePricingRuleParams(id: id),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(successMessage: AppStrings.pricingRuleDeleted));
        unawaited(loadPricingRules(loungeId: loungeId));
      },
    );
  }

  Future<void> fetchLiveQuote({
    required String roomId,
    required String date,
    required String startTime,
    required String endTime,
    String playMode = 'single',
  }) async {
    if (isClosed) return;
    final generation = ++_quoteGeneration;
    final result = await quoteBookingPriceUseCase(
      QuoteBookingPriceParams(
        roomId: roomId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        playMode: playMode,
      ),
    );
    if (isClosed || generation != _quoteGeneration) return;
    result.fold(
      (_) => emit(state.copyWith(liveQuote: null)),
      (quote) => emit(state.copyWith(liveQuote: quote)),
    );
  }

  void setConflictingRules(List<PricingRuleEntity> conflicts) {
    if (isClosed) return;
    emit(state.copyWith(conflictingRules: conflicts));
  }

  void clearConflictingRules() {
    if (isClosed) return;
    emit(state.copyWith(conflictingRules: const []));
  }
}
