import 'dart:convert';
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
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class _Response implements CashierSyncTransport {
  final Map<String, dynamic> response;
  int calls = 0;
  _Response(this.response);
  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> operation) async {
    if (++calls > 1) throw StateError('synthetic interrupted next operation');
    return response;
  }
}

void main() {
  late Directory directory;
  late EncryptedCashierJournal journal;
  Future<Map<String, dynamic>> seed(String kind) async {
    final fixture =
        jsonDecode(
              File(
                'test/fixtures/offline_${kind}_contract.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final operation = fixture['operation'] as Map;
    journal = await EncryptedCashierJournal.open(
      ownerId: operation['actor_id'] as String,
      loungeId: operation['lounge_id'] as String,
      keys: _Keys(),
    );
    await journal.mutate((state) {
      state['outbox'] = [
        operation,
        {...operation, 'id': 'dependent-operation', 'sequence': 2},
      ];
      state['bookings'] = {
        operation['booking_id']: {
          'total_minor': 20000,
          'paid_minor': 5000,
          'sync_status': 'pending',
        },
      };
    });
    return fixture;
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('playspot-receipt-test-');
    Hive.init(directory.path);
  });
  tearDown(() async {
    await journal.close();
    final target = await directory.resolveSymbolicLinks();
    final temporaryRoot = await Directory.systemTemp.resolveSymbolicLinks();
    if (!target.startsWith(
      '$temporaryRoot${Platform.pathSeparator}playspot-receipt-test-',
    )) {
      throw StateError('Unsafe temporary path');
    }
    await Directory(target).delete(recursive: true);
  });
  for (final kind in ['cash', 'order']) {
    test(
      'native PostgreSQL $kind receipt persists canonical balances without overwriting pending projection',
      () async {
        final fixture = await seed(kind);
        final before = await journal.read();
        final response = fixture['response'] as Map<String, dynamic>;
        final transport = _Response(response);
        await expectLater(
          CashierOutboxSynchronizer(
            journal: journal,
            transport: transport,
          ).synchronize(),
          throwsStateError,
        );
        final state = await journal.read();
        expect(state['outbox'], hasLength(1));
        expect(state['outbox'][0]['id'], 'dependent-operation');
        expect(state['bookings'], before['bookings']);
        final receipt =
            response[kind == 'cash' ? 'financial_receipt' : 'order_receipt']
                as Map;
        final canonical =
            state['server_bookings'][receipt['booking_id']] as Map;
        expect(canonical['paid_minor'], receipt['paid_minor']);
        expect(canonical['due_minor'], receipt['due_minor']);
        expect(canonical['last_sequence'], 1);
        expect(state['acknowledgements'][response['operation_id']], response);
      },
    );
  }
  final cashMutations = <String, void Function(Map<String, dynamic>)>{
    'missing financial receipt': (r) => r.remove('financial_receipt'),
    'different booking': (r) =>
        r['financial_receipt']['booking_id'] = 'another-booking',
    'different venue': (r) =>
        r['financial_receipt']['lounge_id'] = 'another-venue',
    'different shift': (r) =>
        r['financial_receipt']['shift_id'] = 'another-shift',
    'missing ledger id': (r) =>
        r['financial_receipt'].remove('shift_payment_id'),
    'wrong collected amount': (r) =>
        r['financial_receipt']['collected_minor'] = 1,
    'collected more than paid': (r) => r['financial_receipt']['paid_minor'] = 1,
    'negative paid': (r) => r['financial_receipt']['paid_minor'] = -1,
    'fractional due': (r) => r['financial_receipt']['due_minor'] = 0.5,
    'numeric string': (r) => r['financial_receipt']['due_minor'] = '6000',
    'NaN': (r) => r['financial_receipt']['due_minor'] = double.nan,
    'Infinity': (r) => r['financial_receipt']['due_minor'] = double.infinity,
    'unsafe numeric range': (r) =>
        r['financial_receipt']['due_minor'] = 9007199254740992,
    'paid flag despite due': (r) =>
        r['financial_receipt']['payment_status'] = 'paid',
    'wrong sequence': (r) => r['sequence'] = 2,
  };
  test(
    'unsupported extension success never clears a locally saved operation',
    () async {
      final fixture = await seed('cash');
      await journal.mutate((state) => state['outbox'][0]['kind'] = 'extend');
      final before = await journal.read();
      await expectLater(
        CashierOutboxSynchronizer(
          journal: journal,
          transport: _Response(fixture['response'] as Map<String, dynamic>),
        ).synchronize(),
        throwsFormatException,
      );
      expect(await journal.read(), before);
    },
  );
  final orderMutations = <String, void Function(Map<String, dynamic>)>{
    'missing order receipt': (r) => r.remove('order_receipt'),
    'different order id': (r) =>
        r['order_receipt']['order_id'] = 'another-order',
    'different quote total': (r) => r['order_receipt']['total_minor'] = 12000,
    'balance does not add up': (r) => r['order_receipt']['paid_minor'] = 100,
    'missing line items': (r) => r['order_receipt']['items'] = [],
    'wrong line quantity': (r) =>
        r['order_receipt']['items'][0]['quantity'] = 1,
    'wrong canonical price': (r) =>
        r['order_receipt']['items'][0]['unit_price'] = 1,
    'wrong product': (r) =>
        r['order_receipt']['items'][0]['extra_id'] = 'another-product',
    'fractional cent': (r) =>
        r['order_receipt']['items'][0]['unit_price'] = 15.001,
    'overflowing price': (r) =>
        r['order_receipt']['items'][0]['unit_price'] = 1e308,
  };
  for (final (kind, mutations) in [
    ('cash', cashMutations),
    ('order', orderMutations),
  ]) {
    for (final entry in mutations.entries) {
      test(
        '$kind ${entry.key} preserves queued operations and all local state',
        () async {
          final fixture = await seed(kind);
          final response = fixture['response'] as Map<String, dynamic>;
          entry.value(response);
          final before = await journal.read();
          final transport = _Response(response);
          await expectLater(
            CashierOutboxSynchronizer(
              journal: journal,
              transport: transport,
            ).synchronize(),
            throwsFormatException,
          );
          expect(await journal.read(), before);
          expect(transport.calls, 1);
        },
      );
    }
  }
}
