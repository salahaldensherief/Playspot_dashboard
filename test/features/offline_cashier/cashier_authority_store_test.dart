import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/local_cashier_commands.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/local_cashier_command.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/cashier_connection_mode.dart';
import 'support/authority_harness.dart';

void main() {
  late AuthorityHarness harness;
  setUp(() async {
    harness = AuthorityHarness();
    await harness.open();
  });
  tearDown(() => harness.dispose());

  Future<void> rejects(
    Map<String, dynamic> response, {
    Matcher matcher = throwsFormatException,
  }) async {
    final before = await harness.journal.read();
    await expectLater(harness.install(response), matcher);
    expect(await harness.journal.read(), before);
  }

  test(
    'renewal persists both immutable grants and preserves old pending financial data on reopen',
    () async {
      await harness.seedPending();
      final before = await harness.journal.read();
      final response = harness.current;
      await harness.install(response);
      response['permissions']['billing_checkout'] = false;
      await harness.journal.close();
      await harness.reopen();
      final after = await harness.journal.read();
      for (final key in [
        'outbox',
        'bookings',
        'next_sequence',
        'receipts',
        'acknowledgements',
        'sync_conflicts',
        'products',
        'shift',
      ]) {
        expect(after[key], before[key], reason: key);
      }
      expect(after['authority'], harness.current);
      expect(
        after['authority_history'].keys,
        unorderedEquals([
          harness.previous['permit_id'],
          harness.current['permit_id'],
        ]),
      );
      expect(
        after['authority_history'][harness.previous['permit_id']]['expires_ms'],
        harness.previous['expires_ms'],
      );
      expect(after['authority_review_required'], false);
    },
  );
  test('fresh installation starts from the actual server sequence', () async {
    harness.now = DateTime.fromMillisecondsSinceEpoch(
      harness.current['server_time_ms'],
      isUtc: true,
    );
    await harness.install(harness.current..['last_applied_sequence'] = 7);
    expect((await harness.journal.read())['next_sequence'], 8);
  });
  test(
    'new operations use the renewed grant without rewriting old queued events',
    () async {
      await harness.seedPending();
      await harness.install(harness.current);
      final op = harness.pending;
      final receipt =
          await LocalCashierCommands(
            harness.journal,
            clock: () => harness.now,
          ).execute(
            LocalCashierCommand(
              id: '00000000-0000-0000-0000-000000000001',
              bookingId: op['booking_id'],
              actorId: op['actor_id'],
              loungeId: op['lounge_id'],
              deviceId: op['device_id'],
              permitId: harness.current['permit_id'],
              shiftId: op['shift_id'],
              occurredAt: harness.now,
              kind: LocalCashierCommandKind.collectCash,
              payload: {'amount_minor': 100},
            ),
          );
      final state = await harness.journal.read();
      expect(state['outbox'], [harness.pending, receipt]);
      expect(receipt['sequence'], 2);
      expect(receipt['permit_id'], harness.current['permit_id']);
      expect(state['bookings'][op['booking_id']]['paid_minor'], 100);
      expect(state['next_sequence'], 3);
    },
  );
  test(
    'lost acknowledgement permits exact old event replay without sequence reset',
    () async {
      await harness.seedPending();
      await harness.install(harness.current..['last_applied_sequence'] = 1);
      final state = await harness.journal.read();
      expect(state['outbox'], [harness.pending]);
      expect(state['next_sequence'], 2);
    },
  );
  test(
    'online heartbeat and explicit offline transition retain the same grant window',
    () async {
      final authority = harness.previous;
      await harness.install(authority);
      authority['online_requested'] = true;
      authority['heartbeat_expires_at'] = harness.now
          .add(const Duration(seconds: 90))
          .toIso8601String();
      await harness.install(authority, mode: CashierConnectionMode.online);
      authority['online_requested'] = false;
      authority['heartbeat_expires_at'] = harness.now.toIso8601String();
      await harness.install(authority);
      expect((await harness.journal.read())['authority_history'], hasLength(1));
    },
  );
  for (final key in ['issued_ms', 'expires_ms', 'permissions']) {
    test(
      'same permit cannot mutate $key even with an otherwise valid response',
      () async {
        await harness.install(harness.previous);
        final changed = harness.previous;
        if (key == 'permissions') {
          changed[key]['billing_checkout'] = false;
        } else if (key == 'issued_ms') {
          changed[key] += 1;
        } else {
          changed[key] -= 1;
        }
        await rejects(changed);
      },
    );
  }
  final invalid = <String, void Function(Map<String, dynamic>)>{
    'different actor': (a) =>
        a['actor_id'] = '00000000-0000-0000-0000-000000000001',
    'different venue': (a) =>
        a['lounge_id'] = '10000000-0000-0000-0000-000000000001',
    'different device': (a) =>
        a['device_id'] = '20000000-0000-0000-0000-000000000001',
    'invalid permit': (a) => a['permit_id'] = 'bad',
    'legacy wire version': (a) => a.remove('protocol_version'),
    'banned account': (a) => a['profile_banned'] = true,
    'disabled account': (a) => a['profile_active'] = false,
    'unapproved venue': (a) => a['lounge_status'] = 'pending',
    'disabled venue': (a) => a['lounge_active'] = false,
    'offline disabled': (a) => a['offline_enabled'] = false,
    'missing timezone': (a) => a['timezone'] = '',
    'wrong connection mode': (a) => a['online_requested'] = true,
    'missing permission': (a) => a['permissions'].remove('billing_checkout'),
    'string permission': (a) => a['permissions']['bookings.manage'] = 'true',
    'session permission revoked': (a) =>
        a['permissions']['sessions_control'] = false,
    'grant beyond 24 hours': (a) => a['expires_ms'] = a['issued_ms'] + 86400001,
    'expired at server': (a) => a['server_time_ms'] = a['expires_ms'],
    'grant issued after server time': (a) =>
        a['issued_ms'] = a['server_time_ms'] + 1,
    'fractional time': (a) => a['issued_ms'] += 0.5,
    'negative sequence': (a) => a['last_applied_sequence'] = -1,
    'fractional sequence': (a) => a['last_applied_sequence'] = 0.5,
    'unsafe integer': (a) => a['last_applied_sequence'] = 9007199254740992,
    'zone-less heartbeat': (a) =>
        a['heartbeat_expires_at'] = '2026-10-01T00:00:00',
    'offline heartbeat in future': (a) => a['heartbeat_expires_at'] = harness
        .now
        .add(const Duration(seconds: 1))
        .toIso8601String(),
  };
  for (final entry in invalid.entries) {
    test('${entry.key} cannot replace queued data', () async {
      await harness.seedPending();
      final authority = harness.current;
      entry.value(authority);
      await rejects(authority);
    });
  }
  for (final delta in [-300001, 300001]) {
    test(
      'clock drift $delta ms refuses authority without local writes',
      () async {
        await harness.seedPending();
        harness.now = harness.now.add(Duration(milliseconds: delta));
        await rejects(harness.current);
      },
    );
  }
  test(
    'out-of-order server response cannot replace a later heartbeat',
    () async {
      await harness.install(harness.previous);
      final older = harness.previous;
      older['server_time_ms'] -= 1;
      older['heartbeat_expires_at'] = harness.now
          .subtract(const Duration(milliseconds: 1))
          .toIso8601String();
      await rejects(older);
    },
  );
  for (final sequence in [2, 9007199254740991]) {
    test(
      'server sequence $sequence cannot skip unrecorded local operations',
      () async {
        await harness.seedPending();
        await rejects(
          harness.current..['last_applied_sequence'] = sequence,
          matcher: throwsStateError,
        );
      },
    );
  }
  test(
    'server counter reset cannot erase acknowledged local operations',
    () async {
      await harness.install(harness.previous);
      await harness.journal.mutate((state) => state['next_sequence'] = 4);
      await rejects(harness.previous, matcher: throwsStateError);
    },
  );
  for (final change in ['gap', 'head', 'next']) {
    test(
      'malformed pending $change blocks renewal and preserves data',
      () async {
        await harness.seedPending();
        await harness.journal.mutate((state) {
          if (change == 'gap') {
            state['outbox'].add(harness.pending..['sequence'] = 3);
            state['next_sequence'] = 4;
          }
          if (change == 'head') {
            state['outbox'] = ['invalid'];
          }
          if (change == 'next') {
            state['next_sequence'] = 3;
          }
        });
        await rejects(harness.current, matcher: throwsStateError);
      },
    );
  }
  test(
    'unknown legacy grant is preserved and prevents new commands after renewal',
    () async {
      await harness.seedPending();
      await harness.journal.mutate((state) {
        state['authority'].remove('protocol_version');
        state.remove('authority_history');
      });
      await harness.install(harness.current);
      final before = await harness.journal.read();
      expect(before['authority_review_required'], true);
      final op = harness.pending;
      await expectLater(
        LocalCashierCommands(harness.journal, clock: () => harness.now).execute(
          LocalCashierCommand(
            id: '00000000-0000-0000-0000-000000000001',
            bookingId: op['booking_id'],
            actorId: op['actor_id'],
            loungeId: op['lounge_id'],
            deviceId: op['device_id'],
            permitId: harness.current['permit_id'],
            shiftId: op['shift_id'],
            occurredAt: harness.now,
            kind: LocalCashierCommandKind.collectCash,
            payload: {'amount_minor': 100},
          ),
        ),
        throwsStateError,
      );
      expect(await harness.journal.read(), before);
    },
  );
}
