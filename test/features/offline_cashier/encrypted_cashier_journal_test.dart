import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
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

void main() {
  const actor = '00000000-0000-0000-0000-000000000001';
  const lounge = '10000000-0000-0000-0000-000000000001';
  late Directory directory;
  late _Keys keys;
  late EncryptedCashierJournal journal;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('playspot-journal-test-');
    Hive.init(directory.path);
    keys = _Keys();
    journal = await EncryptedCashierJournal.open(
      ownerId: actor,
      loungeId: lounge,
      keys: keys,
    );
  });
  tearDown(() async {
    await journal.close();
    final target = await directory.resolveSymbolicLinks();
    final temporaryRoot = await Directory.systemTemp.resolveSymbolicLinks();
    if (!target.startsWith(
      '$temporaryRoot${Platform.pathSeparator}playspot-journal-test-',
    )) {
      throw StateError(
        'Refusing to delete a path outside this test temporary directory',
      );
    }
    await Directory(target).delete(recursive: true);
  });
  test(
    'booking and queued command survive close and reopen encrypted',
    () async {
      await journal.mutate((state) {
        (state['bookings'] as Map)['booking-1'] = {
          'customer': 'private-customer-marker',
        };
        (state['outbox'] as List).add({'id': 'command-1'});
      });
      await journal.close();
      journal = await EncryptedCashierJournal.open(
        ownerId: actor,
        loungeId: lounge,
        keys: keys,
      );
      final state = await journal.read();
      expect((state['bookings'] as Map)['booking-1'], {
        'customer': 'private-customer-marker',
      });
      expect(state['outbox'], [
        {'id': 'command-1'},
      ]);
      await journal.close();
      for (final file in directory.listSync().whereType<File>()) {
        expect(
          String.fromCharCodes(file.readAsBytesSync()),
          isNot(contains('private-customer-marker')),
        );
      }
    },
  );
  test('overlapping writes serialize without losing commands', () async {
    await Future.wait(
      List.generate(
        30,
        (index) => journal.mutate((state) {
          (state['outbox'] as List).add({'id': index});
        }),
      ),
    );
    expect((await journal.read())['outbox'], hasLength(30));
  });
  test(
    'failed mutation commits neither projection nor outbox and does not poison queue',
    () async {
      await expectLater(
        journal.mutate((state) {
          (state['outbox'] as List).add({'id': 'failed'});
          throw StateError('synthetic failure');
        }),
        throwsStateError,
      );
      await journal.mutate(
        (state) => (state['outbox'] as List).add({'id': 'accepted'}),
      );
      expect((await journal.read())['outbox'], [
        {'id': 'accepted'},
      ]);
    },
  );
  test('readers cannot mutate persistent state', () async {
    final detached = await journal.read();
    (detached['outbox'] as List).add({'id': 'forged'});
    expect((await journal.read())['outbox'], isEmpty);
  });
  test(
    'lost encryption key fails closed and preserves unsynchronized data',
    () async {
      await journal.mutate(
        (state) => (state['outbox'] as List).add({'id': 'unsynced'}),
      );
      await journal.close();
      final savedKeys = Map<String, String>.of(keys.values);
      keys.values.clear();
      await expectLater(
        EncryptedCashierJournal.open(
          ownerId: actor,
          loungeId: lounge,
          keys: keys,
        ),
        throwsStateError,
      );
      expect(keys.values, isEmpty);
      keys.values.addAll(savedKeys);
      journal = await EncryptedCashierJournal.open(
        ownerId: actor,
        loungeId: lounge,
        keys: keys,
      );
      expect((await journal.read())['outbox'], [
        {'id': 'unsynced'},
      ]);
    },
  );
  test('concurrent opens share one writer and key', () async {
    final writers = await Future.wait(
      List.generate(
        8,
        (_) => EncryptedCashierJournal.open(
          ownerId: actor,
          loungeId: lounge,
          keys: keys,
        ),
      ),
    );
    expect(writers.every((writer) => identical(writer, journal)), isTrue);
    expect(keys.values, hasLength(1));
  });
  test('another lounge cannot read this lounge commands', () async {
    await journal.mutate(
      (state) => (state['outbox'] as List).add({'id': 'private'}),
    );
    final other = await EncryptedCashierJournal.open(
      ownerId: actor,
      loungeId: '10000000-0000-0000-0000-000000000002',
      keys: keys,
    );
    try {
      expect((await other.read())['outbox'], isEmpty);
    } finally {
      await other.close();
    }
  });
}
