import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_outbox_synchronizer.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_sync_transport.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/encrypted_cashier_journal.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/offline_key_vault.dart';

class _Keys implements OfflineKeyVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String name) async => values[name];
  @override
  Future<void> write(String name, String value) async {
    values[name] = value;
  }
}

class _Transport implements CashierSyncTransport {
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) handler;
  final calls = <Map<String, dynamic>>[];
  _Transport(this.handler);
  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> operation) {
    calls.add(operation);
    return handler(operation);
  }
}

void main() {
  const actor = '00000000-0000-0000-0000-000000000001';
  const lounge = '10000000-0000-0000-0000-000000000001';
  late Directory directory;
  late EncryptedCashierJournal journal;
  Map<String, dynamic> operation(int sequence) => {
    'id': 'operation-$sequence',
    'sequence': sequence,
    'lounge_id': lounge,
    'actor_id': actor,
  };
  Map<String, dynamic> ack(
    Map<String, dynamic> operation, {
    String status = 'applied',
  }) => {
    'operation_id': operation['id'],
    'sequence': operation['sequence'],
    'lounge_id': lounge,
    'status': status,
  };
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('playspot-sync-test-');
    Hive.init(directory.path);
    journal = await EncryptedCashierJournal.open(
      ownerId: actor,
      loungeId: lounge,
      keys: _Keys(),
    );
    await journal.mutate(
      (state) => (state['outbox'] as List).addAll([operation(1), operation(2)]),
    );
  });
  tearDown(() async {
    await journal.close();
    final target = await directory.resolveSymbolicLinks();
    final temporaryRoot = await Directory.systemTemp.resolveSymbolicLinks();
    if (!target.startsWith(
      '$temporaryRoot${Platform.pathSeparator}playspot-sync-test-',
    )) {
      throw StateError('Unsafe temporary path');
    }
    await Directory(target).delete(recursive: true);
  });
  test(
    'operations synchronize in sequence and preserve server acknowledgements',
    () async {
      final transport = _Transport((operation) async => ack(operation));
      final result = await CashierOutboxSynchronizer(
        journal: journal,
        transport: transport,
      ).synchronize();
      expect(result.appliedCount, 2);
      expect(result.pendingCount, 0);
      expect(transport.calls.map((operation) => operation['sequence']), [1, 2]);
      expect((await journal.read())['acknowledgements'], hasLength(2));
    },
  );
  test(
    'lost response retains operation and explicit retry accepts replay receipt',
    () async {
      var fail = true;
      final transport = _Transport((operation) async {
        if (fail) throw StateError('synthetic network failure');
        return ack(operation, status: 'replayed');
      });
      final synchronizer = CashierOutboxSynchronizer(
        journal: journal,
        transport: transport,
      );
      await expectLater(synchronizer.synchronize(), throwsStateError);
      expect((await journal.read())['outbox'], hasLength(2));
      fail = false;
      await synchronizer.synchronize();
      expect(transport.calls.map((operation) => operation['id']), [
        'operation-1',
        'operation-1',
        'operation-2',
      ]);
    },
  );
  test('conflict remains on device and blocks dependent commands', () async {
    final transport = _Transport(
      (operation) async => {
        ...ack(operation, status: 'conflict'),
        'code': 'ROOM_CONFLICT',
      },
    );
    final synchronizer = CashierOutboxSynchronizer(
      journal: journal,
      transport: transport,
    );
    final result = await synchronizer.synchronize();
    expect(result.blockedOperationId, 'operation-1');
    expect(result.pendingCount, 2);
    expect((await journal.read())['outbox'], hasLength(2));
    await synchronizer.synchronize();
    expect(transport.calls, hasLength(1));
  });
  test('unrelated server receipt never deletes local data', () async {
    final transport = _Transport(
      (operation) async => {...ack(operation), 'operation_id': 'wrong-id'},
    );
    await expectLater(
      CashierOutboxSynchronizer(
        journal: journal,
        transport: transport,
      ).synchronize(),
      throwsFormatException,
    );
    expect((await journal.read())['outbox'], hasLength(2));
  });
  test('concurrent sync callers share one flight', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    var first = true;
    final transport = _Transport((operation) async {
      if (first) {
        first = false;
        started.complete();
        await release.future;
      }
      return ack(operation);
    });
    final synchronizer = CashierOutboxSynchronizer(
      journal: journal,
      transport: transport,
    );
    final one = synchronizer.synchronize();
    await started.future;
    final two = synchronizer.synchronize();
    expect(identical(one, two), isTrue);
    release.complete();
    await Future.wait([one, two]);
    expect(transport.calls, hasLength(2));
  });
  test(
    'new local write during sync is preserved and sent after existing commands',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      var first = true;
      final transport = _Transport((operation) async {
        if (first) {
          first = false;
          started.complete();
          await release.future;
        }
        return ack(operation);
      });
      final running = CashierOutboxSynchronizer(
        journal: journal,
        transport: transport,
      ).synchronize();
      await started.future;
      await journal.mutate(
        (state) => (state['outbox'] as List).add(operation(3)),
      );
      release.complete();
      final result = await running;
      expect(result.appliedCount, 3);
      expect(transport.calls.map((operation) => operation['sequence']), [
        1,
        2,
        3,
      ]);
    },
  );
  test(
    'leaving cashier scope retains pending operations despite late acknowledgement',
    () async {
      final started = Completer<void>();
      final response = Completer<Map<String, dynamic>>();
      final transport = _Transport((operation) async {
        started.complete();
        return response.future;
      });
      final synchronizer = CashierOutboxSynchronizer(
        journal: journal,
        transport: transport,
      );
      final running = synchronizer.synchronize();
      final failure = expectLater(running, throwsStateError);
      await started.future;
      synchronizer.stop();
      response.complete(ack(operation(1)));
      await failure;
      expect((await journal.read())['outbox'], hasLength(2));
      expect(transport.calls, hasLength(1));
    },
  );
}
