import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/lounges/domain/repositories/lounge_repository.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/watch_active_sessions_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/extend_session_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/add_extras_to_session_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/end_session_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/review_extension_request_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/handle_client_request_action_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final LoungeRepository loungeRepository;
  final WatchActiveSessionsUseCase watchActiveSessionsUseCase;
  final ExtendSessionUseCase extendSessionUseCase;
  final AddExtrasToSessionUseCase addExtrasToSessionUseCase;
  final EndSessionUseCase endSessionUseCase;
  final ReviewExtensionRequestUseCase reviewExtensionRequestUseCase;
  final HandleClientRequestActionUseCase handleClientRequestActionUseCase;

  StreamSubscription<List<Booking>>? _activeSessionsSubscription;
  String? _watchedLoungeId;

  DashboardCubit({
    required this.loungeRepository,
    required this.watchActiveSessionsUseCase,
    required this.extendSessionUseCase,
    required this.addExtrasToSessionUseCase,
    required this.endSessionUseCase,
    required this.reviewExtensionRequestUseCase,
    required this.handleClientRequestActionUseCase,
  }) : super(DashboardState.init());

  void startWatchingActiveSessions({String? loungeId}) {
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;

    if (_activeSessionsSubscription != null && _watchedLoungeId == cleanLoungeId) {
      return;
    }

    _watchedLoungeId = cleanLoungeId;
    _activeSessionsSubscription?.cancel();

    _activeSessionsSubscription = watchActiveSessionsUseCase(loungeId: cleanLoungeId).listen(
      (sessions) {
        if (isClosed) return;

        double totalRevenue = 0.0;
        int totalExtrasCount = 0;
        double totalPlayHours = 0.0;

        for (final booking in sessions) {
          totalRevenue += booking.totalPrice;
          totalExtrasCount += booking.extras.length;
          totalPlayHours += (booking.durationMinutes / 60.0);
        }

        final statsMap = {
          'active_count': sessions.length,
          'total_revenue': totalRevenue,
          'total_extras_count': totalExtrasCount,
          'total_play_hours': totalPlayHours,
        };

        emit(state.copyWith(
          status: FeatureStatus.success,
          activeSessionsList: sessions,
          activeSessionsStats: statsMap,
          activeSessions: sessions.length,
        ));
      },
      onError: (error) {
        if (isClosed) return;
        debugPrint('🔴 [DASHBOARD_CUBIT] watchActiveSessions Error: $error');
        emit(state.copyWith(
          status: FeatureStatus.failure,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  Future<bool> extendSession(String bookingId, int additionalMinutes, {double? additionalCost}) async {
    final result = await extendSessionUseCase(bookingId, additionalMinutes, additionalCost: additionalCost);
    if (isClosed) return false;

    return result.fold(
      (failure) {
        debugPrint('🔴 [DASHBOARD_CUBIT] extendSession Failed: ${failure.message}');
        emit(state.copyWith(
          status: FeatureStatus.failure,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) {
        debugPrint('🟢 [DASHBOARD_CUBIT] extendSession Succeeded');
        return true;
      },
    );
  }

  Future<bool> addExtrasToSession(String bookingId, List<Map<String, dynamic>> extras, double additionalCost) async {
    final result = await addExtrasToSessionUseCase(bookingId, extras, additionalCost);
    if (isClosed) return false;

    return result.fold(
      (failure) {
        debugPrint('🔴 [DASHBOARD_CUBIT] addExtrasToSession Failed: ${failure.message}');
        emit(state.copyWith(
          status: FeatureStatus.failure,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) {
        debugPrint('🟢 [DASHBOARD_CUBIT] addExtrasToSession Succeeded');
        return true;
      },
    );
  }

  Future<bool> endSession(String bookingId) async {
    final result = await endSessionUseCase(bookingId);
    if (isClosed) return false;

    return result.fold(
      (failure) {
        debugPrint('🔴 [DASHBOARD_CUBIT] endSession Failed: ${failure.message}');
        emit(state.copyWith(
          status: FeatureStatus.failure,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) {
        debugPrint('🟢 [DASHBOARD_CUBIT] endSession Succeeded');
        return true;
      },
    );
  }

  Future<bool> reviewExtensionRequest({
    required String bookingId,
    required bool isApproved,
    required int requestedMinutes,
    required int currentDurationMinutes,
  }) async {
    final result = await reviewExtensionRequestUseCase(
      bookingId: bookingId,
      isApproved: isApproved,
      requestedMinutes: requestedMinutes,
      currentDurationMinutes: currentDurationMinutes,
    );

    if (isClosed) return false;

    return result.fold(
      (failure) {
        debugPrint('🔴 [DASHBOARD_CUBIT] reviewExtensionRequest Failed: ${failure.message}');
        emit(state.copyWith(
          status: FeatureStatus.failure,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) {
        debugPrint('🟢 [DASHBOARD_CUBIT] reviewExtensionRequest Succeeded');
        return true;
      },
    );
  }

  Future<bool> handleClientRequestAction({
    required String requestId,
    required bool isCanteenOrder,
    required bool approve,
    String? bookingId,
    int? extensionMinutes,
    List<Map<String, dynamic>>? extraItems,
    double? extraCost,
  }) async {
    final result = await handleClientRequestActionUseCase(
      requestId: requestId,
      isCanteenOrder: isCanteenOrder,
      approve: approve,
      bookingId: bookingId,
      extensionMinutes: extensionMinutes,
      extraItems: extraItems,
      extraCost: extraCost,
    );

    if (isClosed) return false;

    return result.fold(
      (failure) {
        debugPrint('🔴 [DASHBOARD_CUBIT] handleClientRequestAction Failed: ${failure.message}');
        emit(state.copyWith(
          status: FeatureStatus.failure,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) {
        debugPrint('🟢 [DASHBOARD_CUBIT] handleClientRequestAction Succeeded');
        return true;
      },
    );
  }

  Future<void> loadDashboardData({String? loungeId}) async {
    if (isClosed) return;
    emit(state.copyWith(status: FeatureStatus.loading));
    
    try {
      final statsResult = await loungeRepository.getDashboardStats(loungeId);
      
      statsResult.fold(
        (failure) => emit(state.copyWith(status: FeatureStatus.failure, errorMessage: failure.message)),
        (stats) async {
          DashboardState newState = state.copyWith(
            totalRevenue: (stats['total_revenue'] as num?)?.toDouble() ?? 0.0,
            activeSessions: (stats['active_sessions'] as num?)?.toInt() ?? 0,
            occupancyRate: (stats['occupancy_rate'] as num?)?.toDouble() ?? 0.0,
            activeRoomsCount: (stats['active_rooms_count'] as num?)?.toInt() ?? 0,
            totalPlayHours: (stats['total_play_hours'] as num?)?.toDouble() ?? 0.0,
            revenueTrend: (stats['revenue_trend'] as num?)?.toDouble() ?? 0.0,
            bookingsTrend: (stats['bookings_trend'] as num?)?.toDouble() ?? 0.0,
            occupancyTrend: (stats['occupancy_trend'] as num?)?.toDouble() ?? 0.0,
          );

          if (loungeId == null) {
            final overviewResult = await loungeRepository.getDashboardOverview();
            final chartResult = await loungeRepository.getRevenueOverTime(30);
            final topResult = await loungeRepository.getTopLoungesByRevenue(10);

            overviewResult.fold(
              (failure) => null,
              (overview) {
                newState = newState.copyWith(
                  totalLounges: (overview['total_lounges'] as num?)?.toInt() ?? 0,
                  activeLounges: (overview['active_lounges'] as num?)?.toInt() ?? 0,
                  totalUsers: (overview['total_users'] as num?)?.toInt() ?? 0,
                  totalBookings: (overview['total_bookings'] as num?)?.toInt() ?? 0,
                  bookingsToday: (overview['bookings_today'] as num?)?.toInt() ?? 0,
                  upcomingBookings: (overview['upcoming_bookings'] as num?)?.toInt() ?? 0,
                  completedBookings: (overview['completed_bookings'] as num?)?.toInt() ?? 0,
                  cancelledBookings: (overview['cancelled_bookings'] as num?)?.toInt() ?? 0,
                  pendingRevenue: (overview['pending_revenue'] as num?)?.toDouble() ?? 0.0,
                  totalPlatformCommission: (overview['total_platform_commission'] as num?)?.toDouble() ?? 0.0,
                );
              },
            );

            chartResult.fold((_) => null, (chart) => newState = newState.copyWith(revenueChart: chart));
            topResult.fold((_) => null, (top) => newState = newState.copyWith(topLounges: top));
          }

          emit(newState.copyWith(status: FeatureStatus.success));
        },
      );
    } catch (e) {
      emit(state.copyWith(status: FeatureStatus.failure, errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _activeSessionsSubscription?.cancel();
    return super.close();
  }
}
