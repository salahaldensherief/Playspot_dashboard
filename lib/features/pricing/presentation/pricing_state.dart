import 'package:equatable/equatable.dart';
import '../domain/entities/pricing_quote_entity.dart';
import '../domain/entities/pricing_rule_entity.dart';

enum PricingStatus { initial, loading, success, failure }

enum PricingGroupBy { lounge, spaceType, room }

class PricingState extends Equatable {
  final PricingStatus status;
  final List<PricingRuleEntity> rules;
  final PricingGroupBy groupBy;
  final List<PricingRuleEntity> conflictingRules;
  final PricingQuoteEntity? liveQuote;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const PricingState({
    this.status = PricingStatus.initial,
    this.rules = const [],
    this.groupBy = PricingGroupBy.lounge,
    this.conflictingRules = const [],
    this.liveQuote,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  PricingState copyWith({
    PricingStatus? status,
    List<PricingRuleEntity>? rules,
    PricingGroupBy? groupBy,
    List<PricingRuleEntity>? conflictingRules,
    PricingQuoteEntity? liveQuote,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return PricingState(
      status: status ?? this.status,
      rules: rules ?? this.rules,
      groupBy: groupBy ?? this.groupBy,
      conflictingRules: conflictingRules ?? this.conflictingRules,
      liveQuote: liveQuote ?? this.liveQuote,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        rules,
        groupBy,
        conflictingRules,
        liveQuote,
        isSaving,
        errorMessage,
        successMessage,
      ];
}
