import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/usecases/base_usecase.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../../domain/usecases/loyalty_usecases.dart';
import '../../../marketing/domain/entities/redemption_option_entity.dart';
import 'loyalty_state.dart';

class LoyaltyCubit extends Cubit<LoyaltyState> {
  final GetLoyaltyStatsUseCase _getLoyaltyStatsUseCase;
  final GetReferralsUseCase _getReferralsUseCase;
  final GetLoyaltyTasksUseCase _getLoyaltyTasksUseCase;
  final UpdateLoyaltyTaskUseCase _updateLoyaltyTaskUseCase;
  final GetLoyaltyLevelsUseCase _getLoyaltyLevelsUseCase;
  final UpdateLoyaltyLevelUseCase _updateLoyaltyLevelUseCase;
  final AdjustUserPointsUseCase _adjustUserPointsUseCase;
  final GetPointsTransactionsPageUseCase _getPointsTransactionsPageUseCase;
  final GetRedemptionOptionsUseCase _getRedemptionOptionsUseCase;
  final CreateRedemptionOptionUseCase _createRedemptionOptionUseCase;
  final UpdateRedemptionOptionUseCase _updateRedemptionOptionUseCase;
  final DeleteRedemptionOptionUseCase _deleteRedemptionOptionUseCase;

  LoyaltyCubit({
    required GetLoyaltyStatsUseCase getLoyaltyStatsUseCase,
    required GetReferralsUseCase getReferralsUseCase,
    required GetLoyaltyTasksUseCase getLoyaltyTasksUseCase,
    required UpdateLoyaltyTaskUseCase updateLoyaltyTaskUseCase,
    required GetLoyaltyLevelsUseCase getLoyaltyLevelsUseCase,
    required UpdateLoyaltyLevelUseCase updateLoyaltyLevelUseCase,
    required AdjustUserPointsUseCase adjustUserPointsUseCase,
    required GetPointsTransactionsPageUseCase getPointsTransactionsPageUseCase,
    required GetRedemptionOptionsUseCase getRedemptionOptionsUseCase,
    required CreateRedemptionOptionUseCase createRedemptionOptionUseCase,
    required UpdateRedemptionOptionUseCase updateRedemptionOptionUseCase,
    required DeleteRedemptionOptionUseCase deleteRedemptionOptionUseCase,
  })  : _getLoyaltyStatsUseCase = getLoyaltyStatsUseCase,
        _getReferralsUseCase = getReferralsUseCase,
        _getLoyaltyTasksUseCase = getLoyaltyTasksUseCase,
        _updateLoyaltyTaskUseCase = updateLoyaltyTaskUseCase,
        _getLoyaltyLevelsUseCase = getLoyaltyLevelsUseCase,
        _updateLoyaltyLevelUseCase = updateLoyaltyLevelUseCase,
        _adjustUserPointsUseCase = adjustUserPointsUseCase,
        _getPointsTransactionsPageUseCase = getPointsTransactionsPageUseCase,
        _getRedemptionOptionsUseCase = getRedemptionOptionsUseCase,
        _createRedemptionOptionUseCase = createRedemptionOptionUseCase,
        _updateRedemptionOptionUseCase = updateRedemptionOptionUseCase,
        _deleteRedemptionOptionUseCase = deleteRedemptionOptionUseCase,
        super(const LoyaltyState());

  Future<void> loadLoyaltyData() async {
    emit(state.copyWith(status: LoyaltyStatus.loading));

    final statsResult = await _getLoyaltyStatsUseCase(GetLoyaltyStatsParams(
      startDate: state.startDate,
      endDate: state.endDate,
      levelId: state.selectedLevelId,
      referralStatus: state.selectedReferralStatus,
      userId: state.selectedUserId,
    ));

    final referralsResult = await _getReferralsUseCase(GetReferralsParams(
      startDate: state.startDate,
      endDate: state.endDate,
      status: state.selectedReferralStatus,
      userId: state.selectedUserId,
    ));

    final tasksResult = await _getLoyaltyTasksUseCase(const NoParams());
    final levelsResult = await _getLoyaltyLevelsUseCase(const NoParams());
    final optionsResult = await _getRedemptionOptionsUseCase(const NoParams());

    statsResult.fold(
      (failure) {
        AppLogger.error('Loyalty stats error: ${failure.message}');
        emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message));
      },
      (stats) {
        referralsResult.fold(
          (failure) {
            AppLogger.error('Loyalty referrals error: ${failure.message}');
            emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message));
          },
          (referrals) {
            tasksResult.fold(
              (failure) {
                AppLogger.error('Loyalty tasks error: ${failure.message}');
                emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message));
              },
              (tasks) {
                levelsResult.fold(
                  (failure) {
                    AppLogger.error('Loyalty levels error: ${failure.message}');
                    emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message));
                  },
                  (levels) {
                    optionsResult.fold(
                      (failure) {
                        AppLogger.error('Loyalty redemption options error: ${failure.message}');
                        emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message));
                      },
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
    final result = await _getPointsTransactionsPageUseCase(
      GetPointsTransactionsPageParams(page: page, pageSize: pageSize),
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Points transactions page error: ${failure.message}');
        emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message));
      },
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
    final result = await _updateLoyaltyTaskUseCase(UpdateLoyaltyTaskParams(
      id: id,
      data: {
        'title_ar': titleAr,
        'title_en': titleEn,
        'description_ar': descriptionAr,
        'description_en': descriptionEn,
        'points_reward': pointsReward,
        'is_active': isActive,
      },
    ));

    result.fold(
      (failure) {
        AppLogger.error('Update task error: ${failure.message}');
        emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message));
      },
      (_) => loadLoyaltyData(),
    );
  }

  Future<void> updateLevel(
    String id, {
    required int minPoints,
    required double multiplier,
  }) async {
    final result = await _updateLoyaltyLevelUseCase(UpdateLoyaltyLevelParams(
      id: id,
      data: {
        'min_points': minPoints,
        'multiplier': multiplier,
      },
    ));

    result.fold(
      (failure) {
        AppLogger.error('Update level error: ${failure.message}');
        emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message));
      },
      (_) => loadLoyaltyData(),
    );
  }

  Future<void> adjustUserPoints({
    required String userId,
    required int pointsDelta,
    required String reason,
  }) async {
    final result = await _adjustUserPointsUseCase(AdjustUserPointsParams(
      userId: userId,
      pointsDelta: pointsDelta,
      reason: reason,
    ));

    result.fold(
      (failure) {
        AppLogger.error('Adjust user points error: ${failure.message}');
        emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message));
      },
      (_) => loadLoyaltyData(),
    );
  }

  Future<void> createOption(RedemptionOptionEntity option) async {
    final result = await _createRedemptionOptionUseCase(option);
    result.fold(
      (failure) {
        AppLogger.error('Create redemption option error: ${failure.message}');
        emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message));
      },
      (_) => loadLoyaltyData(),
    );
  }

  Future<void> updateOption(String id, Map<String, dynamic> data) async {
    final result = await _updateRedemptionOptionUseCase(UpdateRedemptionOptionParams(id: id, data: data));
    result.fold(
      (failure) {
        AppLogger.error('Update redemption option error: ${failure.message}');
        emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message));
      },
      (_) => loadLoyaltyData(),
    );
  }

  Future<void> toggleOptionStatus(String id, bool isActive) async {
    await updateOption(id, {'is_active': isActive});
  }

  Future<void> deleteOption(String id) async {
    final result = await _deleteRedemptionOptionUseCase(id);
    result.fold(
      (failure) {
        AppLogger.error('Delete redemption option error: ${failure.message}');
        emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message));
      },
      (_) => loadLoyaltyData(),
    );
  }
}
