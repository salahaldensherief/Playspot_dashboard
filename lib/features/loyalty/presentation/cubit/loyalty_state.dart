import 'package:equatable/equatable.dart';
import '../../data/models/loyalty_stats_model.dart';
import '../../domain/entities/referral_entity.dart';
import '../../domain/entities/loyalty_task_entity.dart';
import '../../domain/entities/loyalty_level_entity.dart';
import '../../../marketing/domain/entities/redemption_option_entity.dart';

enum LoyaltyStatus { initial, loading, success, failure }

class LoyaltyState extends Equatable {
  final LoyaltyStatus status;
  final LoyaltyStatsModel? stats;
  final List<ReferralEntity> referrals;
  final List<LoyaltyTaskEntity> tasks;
  final List<LoyaltyLevelEntity> levels;
  final List<RedemptionOptionEntity> options;
  final int activeTab;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedLevelId;
  final String? selectedReferralStatus;
  final String? selectedUserId;
  final String? errorMessage;

  const LoyaltyState({
    this.status = LoyaltyStatus.initial,
    this.stats,
    this.referrals = const [],
    this.tasks = const [],
    this.levels = const [],
    this.options = const [],
    this.activeTab = 0,
    this.startDate,
    this.endDate,
    this.selectedLevelId,
    this.selectedReferralStatus = 'all',
    this.selectedUserId,
    this.errorMessage,
  });

  LoyaltyState copyWith({
    LoyaltyStatus? status,
    LoyaltyStatsModel? stats,
    List<ReferralEntity>? referrals,
    List<LoyaltyTaskEntity>? tasks,
    List<LoyaltyLevelEntity>? levels,
    List<RedemptionOptionEntity>? options,
    int? activeTab,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedLevelId,
    String? selectedReferralStatus,
    String? selectedUserId,
    String? errorMessage,
  }) {
    return LoyaltyState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      referrals: referrals ?? this.referrals,
      tasks: tasks ?? this.tasks,
      levels: levels ?? this.levels,
      options: options ?? this.options,
      activeTab: activeTab ?? this.activeTab,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedLevelId: selectedLevelId ?? this.selectedLevelId,
      selectedReferralStatus: selectedReferralStatus ?? this.selectedReferralStatus,
      selectedUserId: selectedUserId ?? this.selectedUserId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        stats,
        referrals,
        tasks,
        levels,
        options,
        activeTab,
        startDate,
        endDate,
        selectedLevelId,
        selectedReferralStatus,
        selectedUserId,
        errorMessage,
      ];
}
