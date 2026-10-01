import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/encrypted_cashier_journal.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/offline_key_vault.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/local_cashier_commands.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/local_cashier_command.dart';

class _Keys implements OfflineKeyVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  const actor = '00000000-0000-0000-0000-000000000001';
  const lounge = '10000000-0000-0000-0000-000000000001';
  const booking = '20000000-0000-0000-0000-000000000001';
  final now = DateTime.utc(2026, 10, 1, 10);
  late Directory directory;
  late EncryptedCashierJournal journal;
  late LocalCashierCommands commands;
  var nextId = 1;
  LocalCashierCommand command(
    LocalCashierCommandKind kind,
    Map<String, dynamic> payload, {
    String? id,
    String bookingId = booking,
    String actorId = actor,
  }) => LocalCashierCommand(
    id:
        id ??
        '30000000-0000-0000-0000-${(nextId++).toString().padLeft(12, '0')}',
    bookingId: bookingId,
    actorId: actorId,
    loungeId: lounge,
    deviceId: 'device-1',
    permitId: '40000000-0000-0000-0000-000000000001',
    occurredAt: now,
    kind: kind,
    payload: payload,
  );
  Map<String, dynamic> reservation() => {
    'room_id': 'room-1',
    'start_ms': now.millisecondsSinceEpoch,
    'end_ms': now.add(const Duration(minutes: 60)).millisecondsSinceEpoch,
    'play_mode': 'single',
    'customer_name': 'Offline guest',
  };
  Future<Map> current() async =>
      ((await journal.read())['bookings'] as Map)[booking] as Map;
  setUp(() async {
    nextId = 1;
    directory = await Directory.systemTemp.createTemp('playspot-command-test-');
    Hive.init(directory.path);
    journal = await EncryptedCashierJournal.open(
      ownerId: actor,
      loungeId: lounge,
      keys: _Keys(),
    );
    commands = LocalCashierCommands(journal, clock: () => now);
    await journal.mutate((state) {
      state['authority'] = {
        'actor_id': actor,
        'lounge_id': lounge,
        'device_id': 'device-1',
        'permit_id': '40000000-0000-0000-0000-000000000001',
        'profile_active': true,
        'profile_banned': false,
        'lounge_status': 'active',
        'lounge_active': true,
        'offline_enabled': true,
        'issued_ms': now
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        'expires_ms': now.add(const Duration(days: 1)).millisecondsSinceEpoch,
        'permissions': {
          'bookings.manage': true,
          'sessions_control': true,
          'billing_checkout': true,
        },
      };
      state['shift'] = {'id': 'shift-1', 'actor_id': actor, 'status': 'open'};
      state['rooms'] = {
        'room-1': {
          'is_active': true,
          'status': 'available',
          'single_hour_minor': 10000,
          'multi_hour_minor': 15000,
          'billing_quantum_minutes': 15,
        },
      };
      state['products'] = {
        'water': {
          'is_active': true,
          'is_available': true,
          'track_stock': true,
          'unit_price_minor': 1500,
          'stock_quantity': 4,
        },
      };
    });
  });
  tearDown(() async {
    await journal.close();
    final target = await directory.resolveSymbolicLinks();
    final temporaryRoot = await Directory.systemTemp.resolveSymbolicLinks();
    if (!target.startsWith(
      '$temporaryRoot${Platform.pathSeparator}playspot-command-test-',
    )) {
      throw StateError('Unsafe temporary path');
    }
    await Directory(target).delete(recursive: true);
  });
  test(
    'walk-in reservation, start, items, partial cash and close all queue offline',
    () async {
      await commands.execute(
        command(LocalCashierCommandKind.reserve, reservation()),
      );
      await commands.execute(command(LocalCashierCommandKind.start, {}));
      await commands.execute(
        command(LocalCashierCommandKind.addItems, {
          'items': [
            {'product_id': 'water', 'quantity': 2},
          ],
        }),
      );
      await commands.execute(
        command(LocalCashierCommandKind.collectCash, {'amount_minor': 5000}),
      );
      await commands.execute(command(LocalCashierCommandKind.close, {}));
      expect((await current())['status'], 'completed');
      expect((await current())['total_minor'], 13000);
      expect((await current())['paid_minor'], 5000);
      final state = await journal.read();
      expect((state['shift'] as Map)['collected_cash_minor'], 5000);
      expect((state['products'] as Map)['water']['stock_quantity'], 2);
      expect((state['outbox'] as List).map((item) => item['sequence']), [
        1,
        2,
        3,
        4,
        5,
      ]);
    },
  );
  test(
    'same command replays exactly once even after acknowledgement removed from outbox',
    () async {
      final reserve = command(LocalCashierCommandKind.reserve, reservation());
      await commands.execute(reserve);
      await journal.mutate((state) => (state['outbox'] as List).clear());
      final receipt = await commands.execute(reserve);
      expect(receipt['sequence'], 1);
      expect((await journal.read())['outbox'], isEmpty);
    },
  );
  test('same id with altered payload rejected', () async {
    final reserve = command(LocalCashierCommandKind.reserve, reservation());
    await commands.execute(reserve);
    await expectLater(
      commands.execute(
        command(LocalCashierCommandKind.reserve, {
          ...reservation(),
          'customer_name': 'Different',
        }, id: reserve.id),
      ),
      throwsStateError,
    );
  });
  test('duplicate cash command never double counts the shift', () async {
    await commands.execute(
      command(LocalCashierCommandKind.reserve, reservation()),
    );
    final payment = command(LocalCashierCommandKind.collectCash, {
      'amount_minor': 3000,
    });
    await commands.execute(payment);
    await commands.execute(payment);
    expect((await current())['paid_minor'], 3000);
  });
  test('conflicting room bookings serialize and accept only one', () async {
    final first = commands.execute(
      command(LocalCashierCommandKind.reserve, reservation()),
    );
    final second = commands.execute(
      command(
        LocalCashierCommandKind.reserve,
        reservation(),
        bookingId: '20000000-0000-0000-0000-000000000002',
      ),
    );
    await first;
    await expectLater(second, throwsStateError);
    expect((await journal.read())['outbox'], hasLength(1));
  });
  test('client supplied price cannot override cached resource price', () async {
    await expectLater(
      commands.execute(
        command(LocalCashierCommandKind.reserve, {
          ...reservation(),
          'total_minor': 1,
        }),
      ),
      throwsStateError,
    );
    expect((await journal.read())['bookings'], isEmpty);
  });
  test('failing second order line rolls back first stock deduction', () async {
    await commands.execute(
      command(LocalCashierCommandKind.reserve, reservation()),
    );
    await commands.execute(command(LocalCashierCommandKind.start, {}));
    await expectLater(
      commands.execute(
        command(LocalCashierCommandKind.addItems, {
          'items': [
            {'product_id': 'water', 'quantity': 2},
            {'product_id': 'unknown', 'quantity': 1},
          ],
        }),
      ),
      throwsStateError,
    );
    expect((await journal.read())['products']['water']['stock_quantity'], 4);
    expect((await current())['items'], isEmpty);
  });
  test(
    'an overdue running session prevents a second session from starting',
    () async {
      await commands.execute(
        command(LocalCashierCommandKind.reserve, reservation()),
      );
      await journal.mutate((state) {
        state['bookings']['overdue'] = {
          'id': 'overdue',
          'room_id': 'room-1',
          'status': 'in_progress',
          'start_ms': now
              .subtract(const Duration(hours: 2))
              .millisecondsSinceEpoch,
          'end_ms': now
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch,
        };
      });
      final before = await journal.read();
      await expectLater(
        commands.execute(command(LocalCashierCommandKind.start, {})),
        throwsStateError,
      );
      expect(await journal.read(), before);
    },
  );
  for (final invalidRoom in [
    {'status': 'maintenance'},
    {'is_active': false},
  ]) {
    test('room changed after reservation $invalidRoom cannot start', () async {
      await commands.execute(
        command(LocalCashierCommandKind.reserve, reservation()),
      );
      await journal.mutate(
        (state) => (state['rooms']['room-1'] as Map).addAll(invalidRoom),
      );
      final before = await journal.read();
      await expectLater(
        commands.execute(command(LocalCashierCommandKind.start, {})),
        throwsStateError,
      );
      expect(await journal.read(), before);
    });
  }
  test('untracked product preserves stock even when it is zero', () async {
    await commands.execute(
      command(LocalCashierCommandKind.reserve, reservation()),
    );
    await commands.execute(command(LocalCashierCommandKind.start, {}));
    await journal.mutate((state) {
      state['products']['water']['track_stock'] = false;
      state['products']['water']['stock_quantity'] = 0;
    });
    await commands.execute(
      command(LocalCashierCommandKind.addItems, {
        'items': [
          {'product_id': 'water', 'quantity': 2},
        ],
      }),
    );
    expect((await journal.read())['products']['water']['stock_quantity'], 0);
    expect((await current())['total_minor'], 13000);
  });
  test(
    'adding items to a paid session makes the new balance partial',
    () async {
      await commands.execute(
        command(LocalCashierCommandKind.reserve, reservation()),
      );
      await commands.execute(command(LocalCashierCommandKind.start, {}));
      await commands.execute(
        command(LocalCashierCommandKind.collectCash, {'amount_minor': 10000}),
      );
      expect((await current())['payment_status'], 'paid');
      await commands.execute(
        command(LocalCashierCommandKind.addItems, {
          'items': [
            {'product_id': 'water', 'quantity': 1},
          ],
        }),
      );
      expect((await current())['payment_status'], 'partial');
      expect((await current())['paid_minor'], 10000);
      expect((await current())['total_minor'], 11500);
    },
  );
  for (final invalid in [
    {'is_available': false},
    {'is_available': null},
    {'stock_quantity': null},
    {'stock_quantity': -1},
  ]) {
    test(
      'unavailable or invalid tracked stock $invalid rolls back order',
      () async {
        await commands.execute(
          command(LocalCashierCommandKind.reserve, reservation()),
        );
        await commands.execute(command(LocalCashierCommandKind.start, {}));
        await journal.mutate(
          (state) => (state['products']['water'] as Map).addAll(invalid),
        );
        final before = await journal.read();
        await expectLater(
          commands.execute(
            command(LocalCashierCommandKind.addItems, {
              'items': [
                {'product_id': 'water', 'quantity': 1},
              ],
            }),
          ),
          throwsStateError,
        );
        expect(await journal.read(), before);
      },
    );
  }
  for (final quantity in [0, -1, 101, 1.5]) {
    test(
      'invalid order quantity $quantity preserves projection and outbox',
      () async {
        await commands.execute(
          command(LocalCashierCommandKind.reserve, reservation()),
        );
        await commands.execute(command(LocalCashierCommandKind.start, {}));
        final before = await journal.read();
        await expectLater(
          commands.execute(
            command(LocalCashierCommandKind.addItems, {
              'items': [
                {'product_id': 'water', 'quantity': quantity},
              ],
            }),
          ),
          throwsStateError,
        );
        expect(await journal.read(), before);
      },
    );
  }
  test('more than fifty lines rejected atomically', () async {
    await commands.execute(
      command(LocalCashierCommandKind.reserve, reservation()),
    );
    await commands.execute(command(LocalCashierCommandKind.start, {}));
    final before = await journal.read();
    await expectLater(
      commands.execute(
        command(LocalCashierCommandKind.addItems, {
          'items': List.generate(
            51,
            (_) => {'product_id': 'water', 'quantity': 1},
          ),
        }),
      ),
      throwsStateError,
    );
    expect(await journal.read(), before);
  });
  for (final amount in [-1, 0, 10001, 1.5]) {
    test('invalid or excess cash $amount rejected without receipt', () async {
      await commands.execute(
        command(LocalCashierCommandKind.reserve, reservation()),
      );
      await expectLater(
        commands.execute(
          command(LocalCashierCommandKind.collectCash, {
            'amount_minor': amount,
          }),
        ),
        throwsStateError,
      );
      expect((await current())['paid_minor'], 0);
      expect((await journal.read())['outbox'], hasLength(1));
    });
  }
  test('banned cached account cannot write', () async {
    await journal.mutate(
      (state) => (state['authority'] as Map)['profile_banned'] = true,
    );
    await expectLater(
      commands.execute(command(LocalCashierCommandKind.reserve, reservation())),
      throwsStateError,
    );
  });
  test('closed shift cannot write', () async {
    await journal.mutate(
      (state) => (state['shift'] as Map)['status'] = 'closed',
    );
    await expectLater(
      commands.execute(command(LocalCashierCommandKind.reserve, reservation())),
      throwsStateError,
    );
  });
  test(
    'missing effective permission denied rather than inferred from role',
    () async {
      await journal.mutate(
        (state) => (state['authority'] as Map)['permissions'] = {},
      );
      await expectLater(
        commands.execute(
          command(LocalCashierCommandKind.reserve, reservation()),
        ),
        throwsStateError,
      );
    },
  );
  test('expired offline authority denied', () async {
    await journal.mutate(
      (state) => (state['authority'] as Map)['expires_ms'] =
          now.millisecondsSinceEpoch,
    );
    await expectLater(
      commands.execute(command(LocalCashierCommandKind.reserve, reservation())),
      throwsStateError,
    );
  });
}
