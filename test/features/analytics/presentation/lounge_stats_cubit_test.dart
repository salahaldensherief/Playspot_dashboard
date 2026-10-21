import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/analytics/domain/entities/lounge_stats_entity.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/get_lounge_owner_stats_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/lounge_stats_cubit.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/lounge_stats_state.dart';

class _StatsUseCase extends Mock implements GetLoungeOwnerStatsUseCase {}

LoungeStatsEntity _stats(String loungeId) => LoungeStatsEntity(
  success: true,
  loungeId: loungeId,
  todayRevenue: 100,
  monthlyRevenue: 1000,
  totalRooms: 4,
  occupiedRooms: 2,
  occupancyRate: 0.5,
  activeBookings: 2,
  openShifts: 1,
  lowStockItems: 0,
);

void main() {
  test('ignores an old lounge response after the scope changes', () async {
    final useCase = _StatsUseCase();
    final oldResponse = Completer<Either<Failure, LoungeStatsEntity>>();
    final newResponse = Completer<Either<Failure, LoungeStatsEntity>>();
    when(() => useCase.call('old')).thenAnswer((_) => oldResponse.future);
    when(() => useCase.call('new')).thenAnswer((_) => newResponse.future);
    final cubit = LoungeStatsCubit(useCase);
    addTearDown(cubit.close);

    final oldRequest = cubit.fetchStats('old');
    final newRequest = cubit.fetchStats('new');
    newResponse.complete(Right(_stats('new')));
    await newRequest;
    oldResponse.complete(Right(_stats('old')));
    await oldRequest;

    expect(cubit.state.status, LoungeStatsStatus.success);
    expect(cubit.state.stats?.loungeId, 'new');
  });

  test('clears previous lounge data before loading another lounge', () async {
    final useCase = _StatsUseCase();
    final nextResponse = Completer<Either<Failure, LoungeStatsEntity>>();
    when(
      () => useCase.call('first'),
    ).thenAnswer((_) async => Right(_stats('first')));
    when(() => useCase.call('second')).thenAnswer((_) => nextResponse.future);
    final cubit = LoungeStatsCubit(useCase);
    addTearDown(cubit.close);

    await cubit.fetchStats('first');
    final pending = cubit.fetchStats('second');
    expect(cubit.state.status, LoungeStatsStatus.loading);
    expect(cubit.state.stats, isNull);
    nextResponse.complete(Right(_stats('second')));
    await pending;

    await cubit.fetchStats(null);
    expect(cubit.state.status, LoungeStatsStatus.initial);
    expect(cubit.state.stats, isNull);
  });
}
