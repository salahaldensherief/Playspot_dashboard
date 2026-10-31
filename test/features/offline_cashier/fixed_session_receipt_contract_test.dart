import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_outbox_synchronizer.dart';
import 'support/fixed_session_harness.dart';
import 'support/fixed_session_transport.dart';

void main() {
  late FixedSessionHarness h;
  setUp(() async {
    h = FixedSessionHarness();
    await h.open();
  });
  tearDown(() => h.dispose());
  for (final kind in ['reserve', 'start', 'close']) {
    test(
      'native PostgreSQL $kind receipt preserves pending projection and persists operational facts',
      () async {
        await h.seedPair(kind);
        final before = await h.journal.read();
        final result = await CashierOutboxSynchronizer(
          journal: h.journal,
          transport: FixedSessionTransport((_) => h.response(kind)),
        ).synchronize();
        expect(result.appliedCount, 1);
        final state = await h.journal.read();
        expect(state['outbox'], isEmpty);
        expect(state['bookings'], before['bookings']);
        final receipt = h.response(kind)['session_receipt'];
        final projection = state['server_bookings'][receipt['booking_id']];
        for (final key in [
          'room_id',
          'shift_id',
          'status',
          'timezone',
          'start_ms',
          'end_ms',
          'capacity_end_ms',
          'started_at',
          'closed_at',
          'paid_minor',
          'due_minor',
        ]) {
          expect(projection[key], receipt[key], reason: key);
        }
      },
    );
  }
  test(
    'real local commands match all five native envelopes and reconcile without repeating money',
    () async {
      final names = ['reserve', 'start', 'order', 'cash', 'close'];
      for (final name in names) {
        expect(
          await h.commands.execute(h.command(h.operation(name))),
          h.operation(name),
          reason: name,
        );
      }
      final pending = await h.journal.read();
      final transport = FixedSessionTransport(
        (op) => h.response(names[(op['sequence'] as int) - 1]),
      );
      final result = await CashierOutboxSynchronizer(
        journal: h.journal,
        transport: transport,
      ).synchronize();
      expect(result.appliedCount, 5);
      final state = await h.journal.read();
      expect(state['bookings'], pending['bookings']);
      expect(
        state['server_bookings'][h.operation(
          'close',
        )['booking_id']]['due_minor'],
        8000,
      );
      expect(
        state['server_bookings'][h.operation('close')['booking_id']]['status'],
        'completed',
      );
      for (final name in names) {
        expect(
          await h.commands.execute(h.command(h.operation(name))),
          h.operation(name),
        );
      }
      expect((await h.journal.read())['outbox'], isEmpty);
      expect(transport.calls, 5);
    },
  );
  final mutations = <String, void Function(Map<String, dynamic>)>{
    'missing receipt': (r) => r.remove('session_receipt'),
    'foreign booking': (r) => r['session_receipt']['booking_id'] = 'foreign',
    'foreign hall': (r) => r['session_receipt']['lounge_id'] = 'foreign',
    'foreign shift': (r) => r['session_receipt']['shift_id'] = 'foreign',
    'foreign room': (r) => r['session_receipt']['room_id'] =
        '00000000-0000-0000-0000-000000000000',
    'wrong timezone': (r) => r['session_receipt']['timezone'] = 'Asia/Dubai',
    'changed planned start': (r) => r['session_receipt']['start_ms'] += 60000,
    'changed planned end': (r) => r['session_receipt']['end_ms'] += 60000,
    'wrong quote': (r) => r['session_receipt']['total_minor'] += 1,
    'wrong payment balance': (r) => r['session_receipt']['paid_minor'] += 1,
    'invented cash despite consistent balance': (r) {
      r['session_receipt']['paid_minor'] += 1;
      r['session_receipt']['due_minor'] -= 1;
    },
    'fractional capacity': (r) =>
        r['session_receipt']['capacity_end_ms'] += 0.5,
    'capacity before start': (r) => r['session_receipt']['capacity_end_ms'] =
        r['session_receipt']['start_ms'] - 1,
    'capacity beyond end': (r) => r['session_receipt']['capacity_end_ms'] =
        r['session_receipt']['end_ms'] + 1,
    'wrong status': (r) => r['session_receipt']['status'] = 'cancelled',
  };
  for (final kind in ['reserve', 'start', 'close']) {
    for (final entry in mutations.entries) {
      test('$kind ${entry.key} retains queue and local state', () async {
        await h.seedPair(kind);
        final response = h.response(kind);
        entry.value(response);
        final before = await h.journal.read();
        await expectLater(
          CashierOutboxSynchronizer(
            journal: h.journal,
            transport: FixedSessionTransport((_) => response),
          ).synchronize(),
          throwsFormatException,
        );
        expect(await h.journal.read(), before);
      });
    }
  }
  for (final kind in ['start', 'close']) {
    test('$kind fabricated start timestamp cannot acknowledge', () async {
      await h.seedPair(kind);
      final response = h.response(kind);
      response['session_receipt']['started_at'] = h.operation(
        'reserve',
      )['occurred_at'];
      final before = await h.journal.read();
      await expectLater(
        CashierOutboxSynchronizer(
          journal: h.journal,
          transport: FixedSessionTransport((_) => response),
        ).synchronize(),
        throwsFormatException,
      );
      expect(await h.journal.read(), before);
    });
  }
  test('close wrong release instant cannot acknowledge', () async {
    await h.seedPair('close');
    final response = h.response('close');
    response['session_receipt']['capacity_end_ms'] += 1;
    final before = await h.journal.read();
    await expectLater(
      CashierOutboxSynchronizer(
        journal: h.journal,
        transport: FixedSessionTransport((_) => response),
      ).synchronize(),
      throwsFormatException,
    );
    expect(await h.journal.read(), before);
  });
  test(
    'missing immutable session context cannot acknowledge a success',
    () async {
      await h.seedPair('start');
      await h.journal.mutate(
        (state) => (state['outbox'][0] as Map).remove('quoted_session'),
      );
      final before = await h.journal.read();
      await expectLater(
        CashierOutboxSynchronizer(
          journal: h.journal,
          transport: FixedSessionTransport((_) => h.response('start')),
        ).synchronize(),
        throwsFormatException,
      );
      expect(await h.journal.read(), before);
    },
  );
  test(
    'microsecond close timestamps produce millisecond capacity without losing the operation',
    () async {
      await h.seedPair('close');
      final event = h.now.add(const Duration(microseconds: 123456));
      await h.journal.mutate(
        (state) => state['outbox'][0]['occurred_at'] = event.toIso8601String(),
      );
      final response = h.response('close');
      response['session_receipt']['closed_at'] = event.toIso8601String();
      response['session_receipt']['capacity_end_ms'] =
          event.millisecondsSinceEpoch;
      final result = await CashierOutboxSynchronizer(
        journal: h.journal,
        transport: FixedSessionTransport((_) => response),
      ).synchronize();
      expect(result.appliedCount, 1);
      expect((await h.journal.read())['outbox'], isEmpty);
    },
  );
}
