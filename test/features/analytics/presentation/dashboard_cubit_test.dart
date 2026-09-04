import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/analytics/domain/entities/lounge_stats_entity.dart';
import 'package:play_spot_dashboard/features/analytics/domain/repositories/dashboard_repository.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/add_extras_to_session_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/end_session_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/extend_session_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/handle_client_request_action_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/review_extension_request_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/watch_active_sessions_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_state.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/lounges/domain/repositories/lounge_repository.dart';

class FakeDashboardRepository implements DashboardRepository {
  bool reviewApproved = false;
  bool shouldFail = false;

  @override
  Future<Either<Failure, void>> reviewExtensionRequest({
    required String bookingId,
    required bool isApproved,
    required int requestedMinutes,
    required int currentDurationMinutes,
  }) async {
    if (shouldFail) {
      return const Left(ServerFailure('Database error'));
    }
    reviewApproved = isApproved;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> extendSession(String bookingId, int additionalMinutes, {double? additionalCost}) async {
    if (shouldFail) return const Left(ServerFailure('Failed to extend'));
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> addExtrasToSession(String bookingId, List<Map<String, dynamic>> extras, double additionalCost) async {
    if (shouldFail) return const Left(ServerFailure('Failed to add extras'));
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> endSession(String bookingId) async {
    if (shouldFail) return const Left(ServerFailure('Failed to end session'));
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> handleClientRequestAction({
    required String requestId,
    required bool isCanteenOrder,
    required bool approve,
    String? bookingId,
    int? extensionMinutes,
    List<Map<String, dynamic>>? extraItems,
    double? extraCost,
  }) async {
    if (shouldFail) return const Left(ServerFailure('Failed to handle action'));
    return const Right(null);
  }

  @override
  Future<Either<Failure, LoungeStatsEntity>> getLoungeStats(String? loungeId) async {
    throw UnimplementedError();
  }

  @override
  Stream<List<Booking>> watchActiveSessions({String? loungeId}) {
    return Stream.value([]);
  }
}

class FakeLoungeRepository implements LoungeRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('DashboardCubit Unit Tests', () {
    late FakeDashboardRepository repository;
    late FakeLoungeRepository loungeRepository;
    late DashboardCubit cubit;

    setUp(() {
      repository = FakeDashboardRepository();
      loungeRepository = FakeLoungeRepository();

      cubit = DashboardCubit(
        loungeRepository: loungeRepository,
        watchActiveSessionsUseCase: WatchActiveSessionsUseCase(repository),
        extendSessionUseCase: ExtendSessionUseCase(repository),
        addExtrasToSessionUseCase: AddExtrasToSessionUseCase(repository),
        endSessionUseCase: EndSessionUseCase(repository),
        reviewExtensionRequestUseCase: ReviewExtensionRequestUseCase(repository),
        handleClientRequestActionUseCase: HandleClientRequestActionUseCase(repository),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state should be DashboardState.init()', () {
      expect(cubit.state.status, FeatureStatus.initial);
      expect(cubit.state.activeSessionsList, isEmpty);
    });

    test('reviewExtensionRequest returns true on success and approves request', () async {
      final success = await cubit.reviewExtensionRequest(
        bookingId: 'b_100',
        isApproved: true,
        requestedMinutes: 30,
        currentDurationMinutes: 60,
      );

      expect(success, isTrue);
      expect(repository.reviewApproved, isTrue);
    });

    test('reviewExtensionRequest returns false on failure and updates state error', () async {
      repository.shouldFail = true;

      final success = await cubit.reviewExtensionRequest(
        bookingId: 'b_100',
        isApproved: true,
        requestedMinutes: 30,
        currentDurationMinutes: 60,
      );

      expect(success, isFalse);
      expect(cubit.state.status, FeatureStatus.failure);
      expect(cubit.state.errorMessage, 'Database error');
    });

    test('endSession returns true on success', () async {
      final success = await cubit.endSession('b_200');
      expect(success, isTrue);
    });
  });
}
