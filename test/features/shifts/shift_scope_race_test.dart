import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/shifts/domain/entities/shift_entity.dart';
import 'package:play_spot_dashboard/features/shifts/domain/entities/live_shift_overview_entity.dart';
import 'package:play_spot_dashboard/features/shifts/domain/repositories/shift_repository.dart';
import 'package:play_spot_dashboard/features/shifts/domain/use_cases/get_active_shift_use_case.dart';
import 'package:play_spot_dashboard/features/shifts/domain/use_cases/get_lounge_live_shift_overview_use_case.dart';
import 'package:play_spot_dashboard/features/shifts/domain/use_cases/open_shift_use_case.dart';
import 'package:play_spot_dashboard/features/shifts/domain/use_cases/close_shift_use_case.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';

class _Repository extends Mock implements ShiftRepository {}

void main() {
  late _Repository repository;
  late ShiftCubit cubit;
  late SupabaseClient client;
  setUp(() {
    repository = _Repository();
    client = SupabaseClient('https://example.invalid', 'fixture-key');
    cubit = ShiftCubit(
      repository: repository,
      getActiveShiftUseCase: GetActiveShiftUseCase(repository),
      getLoungeLiveShiftOverviewUseCase: GetLoungeLiveShiftOverviewUseCase(
        repository,
      ),
      openShiftUseCase: OpenShiftUseCase(repository),
      closeShiftUseCase: CloseShiftUseCase(repository),
      supabaseClient: client,
    );
    when(
      () => repository.getActiveShift(any()),
    ).thenAnswer((_) async => const Right(null));
    when(() => repository.getLoungeLiveShiftOverview(any())).thenAnswer(
      (_) async => const Right(LiveShiftOverviewEntity(hasActiveShift: false)),
    );
  });
  tearDown(() async {
    await cubit.close();
    await client.dispose();
  });

  test(
    'no active overview preserves the state that exposes owner open shift',
    () async {
      await cubit.checkActiveShift('lounge');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, ShiftStatus.initial);
      expect(cubit.state.activeShift, isNull);
      expect(cubit.state.liveOverview?.hasActiveShift, isFalse);
    },
  );

  test(
    'late active shift from an old lounge cannot replace the new scope',
    () async {
      final delayed = Completer<Either<Failure, ShiftEntity?>>();
      when(
        () => repository.getActiveShift('old'),
      ).thenAnswer((_) => delayed.future);
      final old = cubit.checkActiveShift('old');
      await cubit.checkActiveShift('new');
      delayed.complete(
        Right(
          ShiftEntity(
            id: 'old-shift',
            loungeId: 'old',
            cashierId: 'cashier',
            startingCash: 10,
            status: 'open',
            startTime: DateTime(2026),
          ),
        ),
      );
      await old;
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.activeShift, isNull);
      expect(cubit.state.status, ShiftStatus.initial);
      verifyNever(() => repository.getLoungeLiveShiftOverview('old'));
    },
  );

  test('late overview does not erase a new lounge state', () async {
    final delayed = Completer<Either<Failure, LiveShiftOverviewEntity>>();
    when(
      () => repository.getLoungeLiveShiftOverview('old'),
    ).thenAnswer((_) => delayed.future);
    await cubit.checkActiveShift('old');
    await cubit.checkActiveShift('new');
    delayed.complete(
      const Right(
        LiveShiftOverviewEntity(hasActiveShift: true, shiftId: 'old-shift'),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, ShiftStatus.initial);
    expect(cubit.state.liveOverview?.hasActiveShift, isFalse);
  });

  test('reset invalidates an outstanding active shift lookup', () async {
    final delayed = Completer<Either<Failure, ShiftEntity?>>();
    when(
      () => repository.getActiveShift('old'),
    ).thenAnswer((_) => delayed.future);
    final old = cubit.checkActiveShift('old');
    cubit.resetToInitial();
    delayed.complete(const Left(ServerFailure('stale denial')));
    await old;
    expect(cubit.state, ShiftState.initial());
  });

  for (final report in ['cashier', 'lounges']) {
    test(
      '$report report failure is visible and a successful retry clears it',
      () async {
        if (report == 'cashier') {
          when(
            () => repository.getCashierPerformance(
              loungeId: any(named: 'loungeId'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            ),
          ).thenAnswer(
            (_) async => const Left(ServerFailure('fixture report failure')),
          );
          await cubit.getCashierPerformance();
        } else {
          when(
            () => repository.getLoungeComparison(
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            ),
          ).thenAnswer(
            (_) async => const Left(ServerFailure('fixture report failure')),
          );
          await cubit.getLoungeComparison();
        }
        expect(cubit.state.status, ShiftStatus.error);
        expect(cubit.state.errorMessage, 'fixture report failure');
        if (report == 'cashier') {
          when(
            () => repository.getCashierPerformance(
              loungeId: any(named: 'loungeId'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            ),
          ).thenAnswer((_) async => const Right([]));
          await cubit.getCashierPerformance();
        } else {
          when(
            () => repository.getLoungeComparison(
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            ),
          ).thenAnswer((_) async => const Right([]));
          await cubit.getLoungeComparison();
        }
        expect(cubit.state.status, ShiftStatus.active);
        expect(cubit.state.errorMessage, isNull);
      },
    );
  }
  test('late open shift denial cannot overwrite a new lounge', () async {
    await cubit.checkActiveShift('old');
    final delayed = Completer<Either<Failure, void>>();
    when(
      () => repository.openShift('old', 10, notes: null),
    ).thenAnswer((_) => delayed.future);
    final opening = cubit.openShift('old', 10);
    await cubit.checkActiveShift('new');
    delayed.complete(const Left(ServerFailure('stale mutation')));
    await opening;
    expect(cubit.state.status, ShiftStatus.initial);
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.activeShift, isNull);
  });

  test(
    'logout invalidates a completed open shift request before verification',
    () async {
      final delayed = Completer<Either<Failure, void>>();
      when(
        () => repository.openShift('old', 10, notes: null),
      ).thenAnswer((_) => delayed.future);
      final opening = cubit.openShift('old', 10);
      cubit.resetToInitial();
      delayed.complete(const Right(null));
      await opening;
      expect(cubit.state, ShiftState.initial());
      verifyNever(() => repository.getActiveShift('old'));
    },
  );
}
