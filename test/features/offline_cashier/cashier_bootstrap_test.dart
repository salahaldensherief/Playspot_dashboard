import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_bootstrap_store.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_bootstrap_transport.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_bootstrap_refresher.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/local_cashier_commands.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/cashier_connection_mode.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/local_cashier_command.dart';
import 'support/authority_harness.dart';

class _Transport implements CashierBootstrapTransport {
  final Completer<Map<String, dynamic>> response = Completer();
  final Completer<void> started = Completer();
  int calls = 0;
  @override
  Future<Map<String, dynamic>> load({
    required String loungeId,
    required String deviceId,
    required CashierConnectionMode mode,
  }) {
    calls++;
    started.complete();
    return response.future;
  }
}

void main() {
  late AuthorityHarness harness;
  late CashierBootstrapStore store;
  const roomId = '00000000-0000-0000-0000-000000000011';
  const bookingId = '00000000-0000-0000-0000-000000000012';
  const productId = '00000000-0000-0000-0000-000000000013';
  const shiftId = '00000000-0000-0000-0000-000000000014';

  setUp(() async {
    harness = AuthorityHarness();
    await harness.open();
    harness.now = DateTime.fromMillisecondsSinceEpoch(
      harness.current['server_time_ms'],
      isUtc: true,
    );
    store = CashierBootstrapStore(harness.store);
  });
  tearDown(() => harness.dispose());

  Map<String, dynamic> snapshot() {
    final authority = harness.current;
    final start = (harness.now.millisecondsSinceEpoch ~/ 60000 + 1) * 60000;
    return {
      'protocol_version': 2,
      'complete': true,
      'authority': authority,
      'coverage': {
        'from_ms': start - 60000,
        'until_ms': authority['expires_ms'],
      },
      'shift': {
        'id': shiftId,
        'actor_id': harness.journal.actorId,
        'lounge_id': harness.journal.loungeId,
        'status': 'open',
        'collected_cash_minor': 3000,
      },
      'rooms': {
        roomId: {
          'id': roomId,
          'lounge_id': harness.journal.loungeId,
          'is_active': true,
          'is_available': true,
          'status': 'available',
          'single_hour_minor': 10000,
          'multi_hour_minor': 15000,
          'offline_supported': true,
          'blocked_intervals': <dynamic>[],
        },
      },
      'products': {
        productId: {
          'id': productId,
          'lounge_id': harness.journal.loungeId,
          'is_active': true,
          'is_available': true,
          'track_stock': true,
          'unit_price_minor': 1500,
          'stock_quantity': 10,
        },
      },
      'bookings': {
        bookingId: {
          'id': bookingId,
          'lounge_id': harness.journal.loungeId,
          'room_id': roomId,
          'timezone': authority['timezone'],
          'start_ms': start,
          'end_ms': start + 3600000,
          'capacity_end_ms': start + 3600000,
          'total_minor': 10000,
          'paid_minor': 3000,
          'payment_status': 'partial',
          'status': 'upcoming',
          'items': <dynamic>[],
          'shift_id': shiftId,
          'offline_supported': true,
          'sync_status': 'synced',
        },
      },
    };
  }

  Future<Map<String, dynamic>> install(Map<String, dynamic> response) async =>
      store.install(
        response,
        deviceId: harness.deviceId,
        mode: CashierConnectionMode.offline,
        expectedState: await store.prepare(),
      );

  test(
    'permit and complete scoped projection survive encrypted Hive reopen',
    () async {
      final response = snapshot();
      await install(response);
      response['products'][productId]['stock_quantity'] = 999;
      await harness.journal.close();
      await harness.reopen();
      final persisted = await harness.journal.read();
      expect(persisted['products'][productId]['stock_quantity'], 10);
      expect(persisted['bookings'][bookingId]['paid_minor'], 3000);
      expect(persisted['shift']['collected_cash_minor'], 3000);
      expect(persisted['authority'], harness.current);
      expect(persisted['next_sequence'], 1);
      expect(persisted['bootstrap']['protocol_version'], 2);
      expect(persisted['outbox'], isEmpty);
    },
  );

  test(
    'actual native PostgreSQL bootstrap output installs through the Dart contract',
    () async {
      final response = Map<String, dynamic>.from(
        jsonDecode(
              File(
                'test/fixtures/offline_bootstrap_contract.json',
              ).readAsStringSync(),
            )
            as Map,
      );
      await harness.journal.close();
      harness.fixtures['current'] = response['authority'];
      harness.now = DateTime.fromMillisecondsSinceEpoch(
        response['authority']['server_time_ms'],
        isUtc: true,
      );
      await harness.reopen();
      store = CashierBootstrapStore(harness.store);
      await install(response);
      await harness.journal.close();
      await harness.reopen();
      final persisted = await harness.journal.read();
      expect(persisted['rooms'], response['rooms']);
      expect(persisted['products'], response['products']);
      expect(persisted['bookings'], response['bookings']);
      expect(persisted['shift'], response['shift']);
      expect(persisted['authority'], response['authority']);
    },
  );

  final corruptions = <String, void Function(Map<String, dynamic>)>{
    'partial response': (r) => r['complete'] = false,
    'foreign shift actor': (r) => r['shift']['actor_id'] = bookingId,
    'closed shift': (r) => r['shift']['status'] = 'closed',
    'foreign room': (r) => r['rooms'][roomId]['lounge_id'] = bookingId,
    'foreign booking': (r) => r['bookings'][bookingId]['lounge_id'] = roomId,
    'mismatched row id': (r) => r['rooms'][roomId]['id'] = bookingId,
    'fractional price': (r) =>
        r['products'][productId]['unit_price_minor'] = 1.5,
    'negative stock': (r) => r['products'][productId]['stock_quantity'] = -1,
    'missing rooms': (r) => r.remove('rooms'),
    'missing capacity row': (r) =>
        r['bookings'][bookingId]['room_id'] = productId,
    'uncovered present': (r) =>
        r['coverage']['from_ms'] = r['authority']['server_time_ms'] + 1,
    'coverage beyond permit': (r) =>
        r['coverage']['until_ms'] = r['authority']['expires_ms'] + 1,
    'foreign timezone': (r) => r['bookings'][bookingId]['timezone'] = 'UTC',
    'inconsistent payment': (r) =>
        r['bookings'][bookingId]['payment_status'] = 'paid',
    'overpayment': (r) => r['bookings'][bookingId]['paid_minor'] = 20000,
    'missing actual start': (r) =>
        r['bookings'][bookingId]['status'] = 'in_progress',
    'unsupported marker missing': (r) =>
        r['rooms'][roomId].remove('offline_supported'),
    'invalid grant': (r) => r['authority']['actor_id'] = bookingId,
    'missing tournament coverage': (r) =>
        r['rooms'][roomId].remove('blocked_intervals'),
    'invalid tournament interval': (r) =>
        r['rooms'][roomId]['blocked_intervals'] = [
          {'start_ms': 1000, 'end_ms': 1000},
        ],
  };
  for (final corruption in corruptions.entries) {
    test('${corruption.key} rolls back both authority and resources', () async {
      final before = await harness.journal.read();
      final response = snapshot();
      corruption.value(response);
      await expectLater(install(response), throwsFormatException);
      expect(await harness.journal.read(), before);
    });
  }

  test('pending operations block bootstrap before a server request', () async {
    harness.now = DateTime.fromMillisecondsSinceEpoch(
      harness.previous['server_time_ms'],
      isUtc: true,
    );
    await harness.seedPending();
    final before = await harness.journal.read();
    final transport = _Transport();
    final refresher = CashierBootstrapRefresher(
      transport: transport,
      store: store,
    );
    await expectLater(
      refresher.refresh(
        deviceId: harness.deviceId,
        mode: CashierConnectionMode.offline,
      ),
      throwsStateError,
    );
    expect(transport.calls, 0);
    expect(await harness.journal.read(), before);
  });

  test(
    'a local operation while fetching cannot be overwritten by a late snapshot',
    () async {
      final response = snapshot();
      final expected = await store.prepare();
      await harness.journal.mutate((state) {
        state['outbox'] = [harness.pending];
        state['next_sequence'] = 2;
      });
      final changed = await harness.journal.read();
      await expectLater(
        store.install(
          response,
          deviceId: harness.deviceId,
          mode: CashierConnectionMode.offline,
          expectedState: expected,
        ),
        throwsStateError,
      );
      expect(await harness.journal.read(), changed);
    },
  );

  test(
    'any intervening projection change requires fetching a new snapshot',
    () async {
      final expected = await store.prepare();
      await harness.journal.mutate(
        (state) => state['shift'] = {'status': 'closed'},
      );
      final changed = await harness.journal.read();
      await expectLater(
        store.install(
          snapshot(),
          deviceId: harness.deviceId,
          mode: CashierConnectionMode.offline,
          expectedState: expected,
        ),
        throwsStateError,
      );
      expect(await harness.journal.read(), changed);
    },
  );

  test(
    'ending the repository while fetching ignores the late response',
    () async {
      final transport = _Transport();
      final refresher = CashierBootstrapRefresher(
        transport: transport,
        store: store,
      );
      final before = await harness.journal.read();
      final request = refresher.refresh(
        deviceId: harness.deviceId,
        mode: CashierConnectionMode.offline,
      );
      final assertion = expectLater(request, throwsStateError);
      await transport.started.future;
      refresher.stop();
      transport.response.complete(snapshot());
      await assertion;
      expect(await harness.journal.read(), before);
    },
  );

  LocalCashierCommand command({
    required Map<String, dynamic> payload,
    LocalCashierCommandKind kind = LocalCashierCommandKind.reserve,
  }) => LocalCashierCommand(
    id: '00000000-0000-0000-0000-000000000021',
    bookingId: kind == LocalCashierCommandKind.reserve
        ? '00000000-0000-0000-0000-000000000022'
        : bookingId,
    actorId: harness.journal.actorId,
    loungeId: harness.journal.loungeId,
    deviceId: harness.deviceId,
    permitId: harness.current['permit_id'],
    shiftId: shiftId,
    occurredAt: harness.now,
    kind: kind,
    payload: payload,
  );

  test('real factory command policy requires a complete bootstrap', () async {
    await harness.install(harness.current);
    await harness.journal.mutate(
      (state) => state['shift'] = snapshot()['shift'],
    );
    final commands = LocalCashierCommands(
      harness.journal,
      clock: () => harness.now,
      requireBootstrap: true,
    );
    await expectLater(commands.execute(command(payload: {})), throwsStateError);
    expect((await harness.journal.read())['outbox'], isEmpty);
  });

  for (final issue in [
    'outside coverage',
    'foreign timezone',
    'unsupported room',
  ]) {
    test(
      '$issue refuses reserve without losing the existing capacity row',
      () async {
        final response = snapshot();
        if (issue == 'unsupported room') {
          response['rooms'][roomId]['offline_supported'] = false;
        }
        await install(response);
        final start = response['bookings'][bookingId]['end_ms'] as int;
        final before = await harness.journal.read();
        final payload = <String, dynamic>{
          'room_id': roomId,
          'start_ms': start,
          'end_ms': start + 3600000,
          'play_mode': 'single',
          'timezone': issue == 'foreign timezone' ? 'UTC' : 'Africa/Cairo',
          'customer_name': 'Local customer',
        };
        if (issue == 'outside coverage') {
          payload['end_ms'] = response['coverage']['until_ms'] + 60000;
        }
        await expectLater(
          LocalCashierCommands(
            harness.journal,
            clock: () => harness.now,
            requireBootstrap: true,
          ).execute(command(payload: payload)),
          throwsStateError,
        );
        expect(await harness.journal.read(), before);
      },
    );
  }

  test('existing booking cash stays tied to its original shift', () async {
    final response = snapshot();
    response['bookings'][bookingId]['shift_id'] = productId;
    await install(response);
    final before = await harness.journal.read();
    await expectLater(
      LocalCashierCommands(
        harness.journal,
        clock: () => harness.now,
        requireBootstrap: true,
      ).execute(
        command(
          payload: {'amount_minor': 100},
          kind: LocalCashierCommandKind.collectCash,
        ),
      ),
      throwsStateError,
    );
    expect(await harness.journal.read(), before);
  });

  test(
    'bootstrapped reserve start cash close persists ordered operations and debt',
    () async {
      final response = snapshot();
      await install(response);
      final start = response['bookings'][bookingId]['end_ms'] as int;
      final reservedId = '00000000-0000-0000-0000-000000000022';
      final commands = LocalCashierCommands(
        harness.journal,
        clock: () => harness.now,
        requireBootstrap: true,
      );
      await commands.execute(
        command(
          payload: {
            'room_id': roomId,
            'start_ms': start,
            'end_ms': start + 3600000,
            'play_mode': 'single',
            'timezone': 'Africa/Cairo',
            'customer_name': 'Local customer',
          },
        ),
      );
      harness.now = DateTime.fromMillisecondsSinceEpoch(start, isUtc: true);
      Future<void> execute(
        int suffix,
        LocalCashierCommandKind kind,
        Map<String, dynamic> payload,
      ) async {
        await commands.execute(
          LocalCashierCommand(
            id: '00000000-0000-0000-0000-0000000000$suffix',
            bookingId: reservedId,
            actorId: harness.journal.actorId,
            loungeId: harness.journal.loungeId,
            deviceId: harness.deviceId,
            permitId: harness.current['permit_id'],
            shiftId: shiftId,
            occurredAt: harness.now,
            kind: kind,
            payload: payload,
          ),
        );
      }

      await execute(23, LocalCashierCommandKind.start, {});
      await execute(24, LocalCashierCommandKind.collectCash, {
        'amount_minor': 4000,
      });
      harness.now = harness.now.add(const Duration(minutes: 30));
      await execute(25, LocalCashierCommandKind.close, {});
      await harness.journal.close();
      await harness.reopen();
      final after = await harness.journal.read();
      expect((after['outbox'] as List).map((op) => op['sequence']), [
        1,
        2,
        3,
        4,
      ]);
      expect(after['bookings'][reservedId]['status'], 'completed');
      expect(after['bookings'][reservedId]['paid_minor'], 4000);
      expect(after['bookings'][reservedId]['total_minor'], 10000);
      expect(after['bookings'][reservedId]['payment_status'], 'partial');
      expect(after['bookings'][reservedId]['capacity_end_ms'], start + 1800000);
      expect(after['shift']['collected_cash_minor'], 7000);
      expect(after['bookings'].containsKey(bookingId), true);
    },
  );

  test(
    'a tournament reservation blocks an offline walk-in in the same room',
    () async {
      final response = snapshot();
      final start = response['bookings'][bookingId]['end_ms'] as int;
      response['rooms'][roomId]['blocked_intervals'] = [
        {'start_ms': start, 'end_ms': start + 3600000},
      ];
      await install(response);
      final before = await harness.journal.read();
      await expectLater(
        LocalCashierCommands(
          harness.journal,
          clock: () => harness.now,
          requireBootstrap: true,
        ).execute(
          command(
            payload: {
              'room_id': roomId,
              'start_ms': start,
              'end_ms': start + 3600000,
              'play_mode': 'single',
              'timezone': 'Africa/Cairo',
              'customer_name': 'Local customer',
            },
          ),
        ),
        throwsStateError,
      );
      expect(await harness.journal.read(), before);
    },
  );
  test(
    'confirmed handover rebases drained journal after another writer advances sequence',
    () async {
      harness.now = DateTime.fromMillisecondsSinceEpoch(
        harness.previous['server_time_ms'],
        isUtc: true,
      );
      await harness.install(harness.previous);
      harness.now = DateTime.fromMillisecondsSinceEpoch(
        harness.current['server_time_ms'],
        isUtc: true,
      );
      await harness.journal.mutate((state) {
        state['writer_release'] = {
          'status': 'released',
          'request': {'p_permit_id': harness.previous['permit_id']},
        };
      });
      final response = snapshot();
      response['authority']['last_applied_sequence'] = 17;
      final before = await store.prepare();
      await store.install(
        response,
        deviceId: harness.deviceId,
        mode: CashierConnectionMode.offline,
        expectedState: before,
      );
      final state = await harness.journal.read();
      expect(state['next_sequence'], 18);
      expect(state['writer_release'], isNull);
      expect(
        state['authority_history'][harness.previous['permit_id']],
        isNotNull,
      );
      expect(state['bookings'], response['bookings']);
    },
  );
}
