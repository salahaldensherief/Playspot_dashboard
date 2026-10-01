import 'package:flutter_test/flutter_test.dart';
import 'support/fixed_session_harness.dart';

void main() {
  late FixedSessionHarness h;
  setUp(() async {
    h = FixedSessionHarness();
    await h.open();
  });
  tearDown(() => h.dispose());
  test(
    '61 minute reservation agrees with canonical fixed-time cent rounding',
    () async {
      final op = h.operation('reserve');
      op['payload']['end_ms'] = op['payload']['start_ms'] + 61 * 60000;
      final queued = await h.commands.execute(h.command(op));
      expect(queued['quoted_total_minor'], 10167);
    },
  );
  for (final patch in [
    {'status': 'maintenance'},
    {'status': 'unrecognized'},
    {'is_active': false},
    {'is_available': false},
    {'is_available': null},
    {'single_hour_minor': 0},
    {'single_hour_minor': 1},
  ]) {
    test(
      'ineligible room or zero-cent quote $patch leaves the journal intact',
      () async {
        await h.journal.mutate(
          (state) =>
              (state['rooms'][h.operation('reserve')['payload']['room_id']]
                      as Map)
                  .addAll(patch),
        );
        final op = h.operation('reserve');
        if (patch['single_hour_minor'] == 1) {
          op['payload']['end_ms'] = op['payload']['start_ms'] + 60000;
        }
        final before = await h.journal.read();
        await expectLater(h.commands.execute(h.command(op)), throwsStateError);
        expect(await h.journal.read(), before);
      },
    );
  }
  for (final patch in [
    {'customer_name': null},
    {'customer_name': 1},
    {'customer_name': ''},
    {'customer_name': 'x' * 121},
    {'customer_phone': 1},
    {'customer_phone': '1' * 33},
  ]) {
    test('invalid cached walk-in identity $patch never queues', () async {
      final op = h.operation('reserve');
      (op['payload'] as Map).addAll(patch);
      final before = await h.journal.read();
      await expectLater(h.commands.execute(h.command(op)), throwsStateError);
      expect(await h.journal.read(), before);
    });
  }
  test(
    'large safe integer rate uses exact rounding without an unsafe intermediate multiplication',
    () async {
      await h.journal.mutate(
        (state) =>
            state['rooms'][h.operation(
                  'reserve',
                )['payload']['room_id']]['single_hour_minor'] =
                9007199254740989,
      );
      final op = h.operation('reserve');
      op['payload']['end_ms'] = op['payload']['start_ms'] + 31 * 60000;
      final receipt = await h.commands.execute(h.command(op));
      expect(receipt['quoted_total_minor'], 4653719614949511);
    },
  );
  for (final minutes in [-1, 60]) {
    test('start outside planned interval $minutes preserves queue', () async {
      await h.commands.execute(h.command(h.operation('reserve')));
      final op = h.operation('start');
      op['occurred_at'] = DateTime.fromMillisecondsSinceEpoch(
        h.operation('reserve')['payload']['start_ms'] + minutes * 60000,
        isUtc: true,
      ).toIso8601String();
      final before = await h.journal.read();
      await expectLater(h.commands.execute(h.command(op)), throwsStateError);
      expect(await h.journal.read(), before);
    });
  }
  test(
    'early close releases only remaining capacity and preserves price and unpaid debt',
    () async {
      for (final kind in ['reserve', 'start']) {
        await h.commands.execute(h.command(h.operation(kind)));
      }
      await h.commands.execute(h.command(h.operation('close')));
      final state = await h.journal.read();
      final closed = state['bookings'][h.operation('reserve')['booking_id']];
      expect(closed['total_minor'], 10000);
      expect(closed['paid_minor'], 0);
      expect(closed['capacity_end_ms'], h.now.millisecondsSinceEpoch);
      expect(closed['end_ms'], h.operation('reserve')['payload']['end_ms']);
      final next = h.operation('reserve');
      next['id'] = '00000000-0000-0000-0000-000000000101';
      next['booking_id'] = '00000000-0000-0000-0000-000000000102';
      next['occurred_at'] = h.now.toIso8601String();
      next['payload']['start_ms'] = h.now.millisecondsSinceEpoch;
      next['payload']['end_ms'] = h.now
          .add(const Duration(hours: 1))
          .millisecondsSinceEpoch;
      await h.commands.execute(h.command(next));
      expect((await h.journal.read())['bookings'].length, 2);
    },
  );
  test(
    'historical occupied portion of an early-closed session still conflicts',
    () async {
      for (final kind in ['reserve', 'start', 'close']) {
        await h.commands.execute(h.command(h.operation(kind)));
      }
      final next = h.operation('reserve');
      next['id'] = '00000000-0000-0000-0000-000000000101';
      next['booking_id'] = '00000000-0000-0000-0000-000000000102';
      final before = await h.journal.read();
      await expectLater(h.commands.execute(h.command(next)), throwsStateError);
      expect(await h.journal.read(), before);
    },
  );
  test('overdue physical occupancy blocks starting adjacent booking', () async {
    await h.commands.execute(h.command(h.operation('reserve')));
    final existing = h.operation('reserve');
    await h.journal.mutate(
      (state) => state['bookings']['other-session'] = {
        'id': 'other-session',
        'room_id': existing['payload']['room_id'],
        'status': 'in_progress',
        'start_ms': existing['payload']['start_ms'] - 7200000,
        'end_ms': existing['payload']['start_ms'] - 3600000,
      },
    );
    final before = await h.journal.read();
    await expectLater(
      h.commands.execute(h.command(h.operation('start'))),
      throwsStateError,
    );
    expect(await h.journal.read(), before);
  });
  test(
    'close earlier than actual recorded start leaves room and debt untouched',
    () async {
      for (final kind in ['reserve', 'start']) {
        await h.commands.execute(h.command(h.operation(kind)));
      }
      final op = h.operation('close');
      op['occurred_at'] = h.operation('reserve')['occurred_at'];
      final before = await h.journal.read();
      await expectLater(h.commands.execute(h.command(op)), throwsStateError);
      expect(await h.journal.read(), before);
    },
  );
}
