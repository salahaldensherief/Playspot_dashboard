import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/cashier_conflict.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/repositories/cashier_conflict_repository.dart';
import 'package:play_spot_dashboard/features/offline_cashier/presentation/cashier_conflict_cubit.dart';
import 'package:play_spot_dashboard/features/offline_cashier/presentation/cashier_conflict_state.dart';

class _MockRepo implements CashierConflictRepository {
  Either<Failure, List<CashierConflict>> loadResult = const Right([]);
  Either<Failure, void> approveResult = const Right(null);
  final loadCalls = <(String, String)>[];
  final approveCalls = <Map<String, String>>[];

  @override
  Future<Either<Failure, List<CashierConflict>>> load(
    String actorId,
    String loungeId,
  ) async {
    loadCalls.add((actorId, loungeId));
    return loadResult;
  }

  @override
  Future<Either<Failure, void>> approve({
    required String actorId,
    required String loungeId,
    required String operationId,
    required String reviewId,
    required String reason,
  }) async {
    approveCalls.add({
      'actorId': actorId,
      'loungeId': loungeId,
      'operationId': operationId,
      'reviewId': reviewId,
      'reason': reason,
    });
    return approveResult;
  }
}

void main() {
  const actor = 'actor-1';
  const lounge = 'lounge-1';
  const conflict = CashierConflict(
    operationId: 'op-1',
    bookingId: 'book-1',
    actorId: actor,
    kind: 'reserve',
    code: 'ROOM_CONFLICT',
    sequence: 1,
    retryPending: false,
  );

  late _MockRepo repo;
  late CashierConflictCubit cubit;

  setUp(() {
    repo = _MockRepo();
    cubit = CashierConflictCubit(repo);
  });

  tearDown(() => cubit.close());

  test('initial state has empty conflicts and initial status', () {
    expect(cubit.state.status, CashierConflictStatus.initial);
    expect(cubit.state.conflicts, isEmpty);
    expect(cubit.state.busy, isFalse);
    expect(cubit.state.error, isNull);
  });

  test('load emits loading then ready with items', () async {
    repo.loadResult = const Right([conflict]);
    await cubit.load(actor, lounge);

    expect(cubit.state.status, CashierConflictStatus.ready);
    expect(cubit.state.conflicts, [conflict]);
    expect(cubit.state.error, isNull);
    expect(repo.loadCalls, hasLength(1));
  });

  test('load emits failure when repo returns failure', () async {
    repo.loadResult = const Left(ServerFailure('offline_conflicts.failed'));
    await cubit.load(actor, lounge);

    expect(cubit.state.status, CashierConflictStatus.failure);
    expect(cubit.state.error, 'offline_conflicts.failed');
  });

  test('approve rejects reason shorter than 10 characters', () async {
    repo.loadResult = const Right([conflict]);
    await cubit.load(actor, lounge);

    await cubit.approve('op-1', 'short');
    expect(cubit.state.error, 'offline_conflicts.reason_invalid');
    expect(repo.approveCalls, isEmpty);
  });

  test('approve submits valid reason and reloads on success', () async {
    repo.loadResult = const Right([conflict]);
    await cubit.load(actor, lounge);

    await cubit.approve('op-1', 'This conflict was resolved manually');
    expect(repo.approveCalls, hasLength(1));
    expect(
      repo.approveCalls.first['reason'],
      'This conflict was resolved manually',
    );
    expect(cubit.state.error, isNull);
    // Reload was called after successful approval
    expect(repo.loadCalls, hasLength(2));
  });

  test('approve emits error on repository failure', () async {
    repo.loadResult = const Right([conflict]);
    await cubit.load(actor, lounge);

    repo.approveResult = const Left(ServerFailure('offline_conflicts.denied'));
    await cubit.approve('op-1', 'This conflict was resolved manually');
    expect(cubit.state.error, 'offline_conflicts.denied');
  });
}
