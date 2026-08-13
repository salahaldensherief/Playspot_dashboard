import 'package:equatable/equatable.dart';
import '../../data/models/loyalty_stats_model.dart';
import '../../../marketing/domain/entities/redemption_option_entity.dart';

enum LoyaltyStatus { initial, loading, success, failure }

class LoyaltyState extends Equatable {
  final LoyaltyStatus status;
  final LoyaltyStatsModel? stats;
  final List<RedemptionOptionEntity> options;
  final String? errorMessage;

  const LoyaltyState({
    this.status = LoyaltyStatus.initial,
    this.stats,
    this.options = const [],
    this.errorMessage,
  });

  LoyaltyState copyWith({
    LoyaltyStatus? status,
    LoyaltyStatsModel? stats,
    List<RedemptionOptionEntity>? options,
    String? errorMessage,
  }) {
    return LoyaltyState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      options: options ?? this.options,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, stats, options, errorMessage];
}
