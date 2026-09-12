import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../../../marketing/domain/entities/redemption_option_entity.dart';
import 'loyalty_state.dart';

class LoyaltyCubit extends Cubit<LoyaltyState> {
  final LoyaltyRepository repository;

  LoyaltyCubit(this.repository) : super(const LoyaltyState());

  Future<void> loadLoyaltyData() async {
    emit(state.copyWith(status: LoyaltyStatus.loading));

    final statsResult = await repository.getLoyaltyStats(
      startDate: state.startDate,
      endDate: state.endDate,
      levelId: state.selectedLevelId,
      referralStatus: state.selectedReferralStatus,
      userId: state.selectedUserId,
    );

    final referralsResult = await repository.getReferrals(
      startDate: state.startDate,
      endDate: state.endDate,
      status: state.selectedReferralStatus,
      userId: state.selectedUserId,
    );

    final tasksResult = await repository.getTasks();
    final levelsResult = await repository.getLevels();
    final optionsResult = await repository.getRedemptionOptions();

    statsResult.fold(
      (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
      (stats) {
        referralsResult.fold(
          (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
          (referrals) {
            tasksResult.fold(
              (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
              (tasks) {
                levelsResult.fold(
                  (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
                  (levels) {
                    optionsResult.fold(
                      (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
                      (options) => emit(state.copyWith(
                        status: LoyaltyStatus.success,
                        stats: stats,
                        referrals: referrals,
                        tasks: tasks,
                        levels: levels,
                        options: options,
                      )),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void changeTab(int tabIndex) {
    emit(state.copyWith(activeTab: tabIndex));
  }

  Future<void> loadPointsTransactionsPage({int page = 1, int pageSize = 20}) async {
    emit(state.copyWith(status: LoyaltyStatus.loading));
    final result = await repository.getPointsTransactionsPage(page: page, pageSize: pageSize);
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
      (paginated) => emit(state.copyWith(
        status: LoyaltyStatus.success,
        pointsTransactions: paginated.items,
        pointsPage: paginated.page,
        pointsPageSize: paginated.pageSize,
        totalPointsCount: paginated.totalCount,
      )),
    );
  }

  Future<void> updateFilters({
    DateTime? startDate,
    DateTime? endDate,
    String? levelId,
    String? referralStatus,
    String? userId,
  }) async {
    emit(state.copyWith(
      startDate: startDate ?? state.startDate,
      endDate: endDate ?? state.endDate,
      selectedLevelId: levelId ?? state.selectedLevelId,
      selectedReferralStatus: referralStatus ?? state.selectedReferralStatus,
      selectedUserId: userId ?? state.selectedUserId,
    ));
    await loadLoyaltyData();
  }

  Future<void> clearFilters() async {
    emit(state.copyWith(
      startDate: null,
      endDate: null,
      selectedLevelId: null,
      selectedReferralStatus: 'all',
      selectedUserId: null,
    ));
    await loadLoyaltyData();
  }

  Future<void> updateTask(
    String id, {
    required String titleAr,
    required String titleEn,
    required String descriptionAr,
    required String descriptionEn,
    required int pointsReward,
    required bool isActive,
  }) async {
    final result = await repository.updateTask(id, {
      'title_ar': titleAr,
      'title_en': titleEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'points_reward': pointsReward,
      'is_active': isActive,
    });

    result.fold(
      (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
      (_) => loadLoyaltyData(),
    );
  }

  Future<void> updateLevel(
    String id, {
    required int minPoints,
    required double multiplier,
  }) async {
    final result = await repository.updateLevel(id, {
      'min_points': minPoints,
      'multiplier': multiplier,
    });

    result.fold(
      (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
      (_) => loadLoyaltyData(),
    );
  }

  Future<void> adjustUserPoints({
    required String userId,
    required int pointsDelta,
    required String reason,
  }) async {
    final result = await repository.adjustUserPoints(
      userId: userId,
      pointsDelta: pointsDelta,
      reason: reason,
    );

    result.fold(
      (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
      (_) => loadLoyaltyData(),
    );
  }

  Future<void> createOption(RedemptionOptionEntity option) async {
    final result = await repository.createRedemptionOption(option);
    result.fold(
      (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
      (_) => loadLoyaltyData(),
    );
  }

  Future<void> updateOption(String id, Map<String, dynamic> data) async {
    final result = await repository.updateRedemptionOption(id, data);
    result.fold(
      (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
      (_) => loadLoyaltyData(),
    );
  }

  Future<void> toggleOptionStatus(String id, bool isActive) async {
    await updateOption(id, {'is_active': isActive});
  }

  Future<void> deleteOption(String id) async {
    final result = await repository.deleteRedemptionOption(id);
    result.fold(
      (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
      (_) => loadLoyaltyData(),
    );
  }
}
