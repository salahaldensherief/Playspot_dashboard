import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/local_cashier_command.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/cashier_sync_result.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/repositories/offline_cashier_repository.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/usecases/execute_offline_cashier_command.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/usecases/synchronize_offline_cashier.dart';

class _Repository extends Mock implements OfflineCashierRepository {}

void main() {
  late _Repository repository;
  final command = LocalCashierCommand(
    id: 'operation',
    bookingId: 'booking',
    actorId: 'actor',
    loungeId: 'lounge',
    deviceId: 'device',
    permitId: 'permit',
    occurredAt: DateTime.utc(2026),
    kind: LocalCashierCommandKind.collectCash,
    payload: {'amount_minor': 100},
  );
  setUp(() => repository = _Repository());
  test('execute returns the durable repository receipt', () async {
    const result = Right<Failure, Map<String, dynamic>>({'sequence': 1});
    when(() => repository.execute(command)).thenAnswer((_) async => result);
    expect(await ExecuteOfflineCashierCommand(repository)(command), result);
    verify(() => repository.execute(command)).called(1);
  });
  test('execute preserves permission failure', () async {
    const result = Left<Failure, Map<String, dynamic>>(
      CacheFailure('offline_cashier.permission_denied'),
    );
    when(() => repository.execute(command)).thenAnswer((_) async => result);
    expect(await ExecuteOfflineCashierCommand(repository)(command), result);
  });
  test(
    'synchronize exposes blocked operation without pretending all operations applied',
    () async {
      const result = Right<Failure, CashierSyncResult>(
        CashierSyncResult(
          appliedCount: 1,
          pendingCount: 2,
          blockedOperationId: 'conflict',
        ),
      );
      when(() => repository.synchronize()).thenAnswer((_) async => result);
      expect(await SynchronizeOfflineCashier(repository)(), result);
      verify(() => repository.synchronize()).called(1);
    },
  );
  test('synchronize preserves retryable failure', () async {
    const result = Left<Failure, CashierSyncResult>(
      NetworkFailure('offline_cashier.sync_failed'),
    );
    when(() => repository.synchronize()).thenAnswer((_) async => result);
    expect(await SynchronizeOfflineCashier(repository)(), result);
  });
}
