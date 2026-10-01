import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/encrypted_cashier_journal.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/local_cashier_commands.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_authority_validator.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/offline_key_vault.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/local_cashier_command.dart';

class FixedSessionHarness implements OfflineKeyVault {
  final keys = <String, String>{};
  late Directory directory;
  late EncryptedCashierJournal journal;
  late LocalCashierCommands commands;
  late Map<String, dynamic> fixtures;

  Map<String, dynamic> operation(String name) =>
      Map<String, dynamic>.from(fixtures[name]['operation'] as Map);
  Map<String, dynamic> response(String name) =>
      Map<String, dynamic>.from(fixtures[name]['response'] as Map);
  DateTime get now =>
      DateTime.parse(operation('close')['occurred_at'] as String);

  Future<void> open() async {
    fixtures =
        jsonDecode(
              File(
                'test/fixtures/offline_fixed_session_contract.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    directory = await Directory.systemTemp.createTemp('playspot-fixed-test-');
    Hive.init(directory.path);
    final op = operation('reserve');
    journal = await EncryptedCashierJournal.open(
      ownerId: op['actor_id'],
      loungeId: op['lounge_id'],
      keys: this,
    );
    commands = LocalCashierCommands(journal, clock: () => now);
    await journal.mutate(_bootstrap);
  }

  void _bootstrap(Map<String, dynamic> state) {
    state['next_sequence'] = 1;
    final op = operation('reserve');
    state['authority'] = {
      'protocol_version': 2,
      for (final key in ['actor_id', 'lounge_id', 'device_id', 'permit_id'])
        key: op[key],
      'profile_active': true,
      'profile_banned': false,
      'lounge_status': 'active',
      'lounge_active': true,
      'offline_enabled': true,
      'issued_ms': now
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch,
      'expires_ms': now.add(const Duration(hours: 23)).millisecondsSinceEpoch,
      'permissions': {
        'bookings.manage': true,
        'sessions_control': true,
        'billing_checkout': true,
      },
    };
    state['authority_history'] = {
      op['permit_id']: CashierAuthorityValidator.immutableFacts(
        state['authority'] as Map,
      ),
    };
    state['shift'] = {
      'id': op['shift_id'],
      'lounge_id': op['lounge_id'],
      'actor_id': op['actor_id'],
      'status': 'open',
    };
    _resources(state, op);
  }

  void _resources(Map<String, dynamic> state, Map op) {
    state['rooms'] = {
      op['payload']['room_id']: {
        'is_active': true,
        'is_available': true,
        'status': 'available',
        'single_hour_minor': 10000,
        'multi_hour_minor': 15000,
        'billing_quantum_minutes': 15,
      },
    };
    state['products'] = {
      operation('order')['payload']['items'][0]['product_id']: {
        'is_active': true,
        'is_available': true,
        'track_stock': true,
        'unit_price_minor': 1500,
        'stock_quantity': 10,
      },
    };
  }

  LocalCashierCommand command(Map op) => LocalCashierCommand(
    id: op['id'],
    bookingId: op['booking_id'],
    actorId: op['actor_id'],
    loungeId: op['lounge_id'],
    deviceId: op['device_id'],
    permitId: op['permit_id'],
    shiftId: op['shift_id'],
    occurredAt: DateTime.parse(op['occurred_at']),
    kind: LocalCashierCommandKind.values.byName(op['kind']),
    payload: Map<String, dynamic>.from(op['payload'] as Map),
  );

  Future<void> seedPair(String kind) => journal.mutate((state) {
    state['outbox'] = [operation(kind)];
    state['bookings'] = {
      operation(kind)['booking_id']: {
        'status': 'completed',
        'total_minor': 13000,
        'paid_minor': 5000,
        'sync_status': 'pending',
      },
    };
  });

  Future<void> dispose() async {
    await journal.close();
    final target = await directory.resolveSymbolicLinks();
    final root = await Directory.systemTemp.resolveSymbolicLinks();
    if (!target.startsWith(
      '$root${Platform.pathSeparator}playspot-fixed-test-',
    )) {
      throw StateError('Unsafe temporary path');
    }
    await Directory(target).delete(recursive: true);
  }

  @override
  Future<String?> read(String key) async => keys[key];
  @override
  Future<void> write(String key, String value) async {
    keys[key] = value;
  }
}
