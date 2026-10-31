import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_authority_store.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/encrypted_cashier_journal.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/offline_key_vault.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/cashier_connection_mode.dart';

class AuthorityHarness implements OfflineKeyVault {
  final keys = <String, String>{};
  late Directory directory;
  late EncryptedCashierJournal journal;
  late CashierAuthorityStore store;
  late Map<String, dynamic> fixtures;
  late DateTime now;
  Map<String, dynamic> get current => _copy(fixtures['current']);
  Map<String, dynamic> get previous => _copy(fixtures['previous']);
  Map<String, dynamic> get pending => _copy(fixtures['pending']);
  String get deviceId => current['device_id'];
  Map<String, dynamic> _copy(Object value) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

  Future<void> open() async {
    fixtures = jsonDecode(
      File('test/fixtures/offline_permit_contract.json').readAsStringSync(),
    );
    now = DateTime.fromMillisecondsSinceEpoch(
      previous['server_time_ms'],
      isUtc: true,
    );
    directory = await Directory.systemTemp.createTemp(
      'playspot-authority-test-',
    );
    Hive.init(directory.path);
    await reopen();
  }

  Future<void> reopen() async {
    journal = await EncryptedCashierJournal.open(
      ownerId: current['actor_id'],
      loungeId: current['lounge_id'],
      keys: this,
    );
    store = CashierAuthorityStore(journal, clock: () => now);
  }

  Future<Map<String, dynamic>> install(
    Map<String, dynamic> response, {
    CashierConnectionMode mode = CashierConnectionMode.offline,
  }) => store.install(response, deviceId: deviceId, mode: mode);

  Future<void> seedPending() async {
    await install(previous);
    await journal.mutate((state) {
      state['outbox'] = [pending];
      state['next_sequence'] = 2;
      state['bookings'] = {
        pending['booking_id']: {
          'lounge_id': pending['lounge_id'],
          'total_minor': 10000,
          'paid_minor': 0,
        },
      };
      state['receipts'] = {pending['id']: pending};
      state['acknowledgements'] = {
        'earlier': {'status': 'applied'},
      };
      state['sync_conflicts'] = {
        'separate': {'code': 'ROOM_UNAVAILABLE'},
      };
      state['products'] = {
        'stock': {'stock_quantity': 3},
      };
      state['shift'] = {
        'id': pending['shift_id'],
        'actor_id': pending['actor_id'],
        'lounge_id': pending['lounge_id'],
        'status': 'open',
      };
    });
    now = DateTime.fromMillisecondsSinceEpoch(
      current['server_time_ms'],
      isUtc: true,
    );
  }

  Future<void> dispose() async {
    await journal.close();
    final target = await directory.resolveSymbolicLinks();
    final root = await Directory.systemTemp.resolveSymbolicLinks();
    if (!target.startsWith(
      '$root${Platform.pathSeparator}playspot-authority-test-',
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
