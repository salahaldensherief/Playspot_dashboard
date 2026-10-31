import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/bookings/domain/repositories/booking_refund_repository.dart';
import 'package:play_spot_dashboard/features/bookings/data/repositories/booking_refund_repository_impl.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_refund_cubit.dart';

Map<String, dynamic> summaryJson({String? operation}) => {
  'booking_id': 'booking',
  'lounge_id': 'lounge',
  'gross_collected_minor': 10000,
  'total_refunded_minor': 0,
  'net_collected_minor': 10000,
  'pending_refund_minor': operation == null ? 0 : 2000,
  'refundable_remaining_minor': operation == null ? 10000 : 8000,
  'movements': [
    {
      'movement_id': 'collection',
      'operation_id': 'collect-op',
      'movement_type': 'collection',
      'payment_method': 'cash',
      'funds_holder': 'lounge',
      'amount_minor': 10000,
    },
  ],
  'refund_requests': operation == null
      ? []
      : [
          {
            'refund_request_id': 'request',
            'operation_id': operation,
            'target_movement_id': 'collection',
            'funds_holder': 'lounge',
            'requested_amount_minor': 2000,
            'status': 'approved_pending_return',
          },
        ],
};
final testSummary = BookingRefundRepositoryImpl.parseSummary(
  summaryJson(),
  'booking',
  'lounge',
);
Map<String, dynamic> initiation(Map<String, dynamic> p) => {
  'success': true,
  'booking_id': p['p_booking_id'],
  'operation_id': p['p_operation_id'],
  'collection_movement_id': p['p_collection_movement_id'],
  'requested_amount_minor': p['p_refund_amount_minor'],
  'policy_override': p['p_policy_override'],
  'funds_holder': 'lounge',
  'status': 'approved_pending_return',
  'refund_request_id': 'request',
};
Future<void> login(SupabaseClient client, {String actor = 'cashier'}) =>
    client.auth.recoverSession(
      jsonEncode({
        'access_token': 'synthetic-token',
        'refresh_token': 'synthetic-refresh',
        'token_type': 'bearer',
        'user': {
          'id': actor,
          'aud': 'authenticated',
          'app_metadata': {},
          'user_metadata': {},
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    );
Future<RefundReceipt> initiate(
  BookingRefundRepository repository, {
  String reason = 'Verified synthetic return',
}) => repository.initiate(
  summary: testSummary,
  collectionId: 'collection',
  amountMinor: 2000,
  reason: reason,
  policyOverride: false,
);
Matcher failure(RefundFailureKind kind) =>
    isA<RefundFailure>().having((e) => e.kind, 'kind', kind);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'decimal parser preserves Arabic/English cents and rejects rounding',
    () {
      expect(refundAmountMinor('١٢٫٣٤'), 1234);
      expect(refundAmountMinor('12.3'), 1230);
      for (final value in ['0', '-1', '1.001', '1e4', '1,00', 'NaN', '']) {
        expect(refundAmountMinor(value), isNull);
      }
    },
  );
  test('canonical summary separates actual money from reserved requests', () {
    final summary = BookingRefundRepositoryImpl.parseSummary(
      summaryJson(operation: 'op'),
      'booking',
      'lounge',
    );
    expect(summary.netMinor, 10000);
    expect(summary.pendingMinor, 2000);
    expect(summary.availableFor(summary.movements.single), 8000);
  });
  for (final field in [
    'booking_id',
    'lounge_id',
    'net_collected_minor',
    'movements',
    'gross_collected_minor',
  ]) {
    test('malformed or foreign summary fails closed: $field', () {
      final raw = summaryJson()
        ..[field] = field.endsWith('_id') ? 'foreign' : null;
      expect(
        () =>
            BookingRefundRepositoryImpl.parseSummary(raw, 'booking', 'lounge'),
        throwsFormatException,
      );
    });
  }
  test('inconsistent movement and request totals fail closed', () {
    final raw = summaryJson()..['gross_collected_minor'] = 9000;
    expect(
      () => BookingRefundRepositoryImpl.parseSummary(raw, 'booking', 'lounge'),
      throwsFormatException,
    );
  });
  test(
    'lost ACK retains ID across repository recreation and blocks changed intent',
    () async {
      final calls = <Map<String, dynamic>>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'synthetic',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          final p = jsonDecode(r.body) as Map<String, dynamic>;
          calls.add(p);
          if (calls.length == 1) {
            throw http.ClientException('Synthetic lost ACK');
          }
          return http.Response(
            jsonEncode(initiation(p)),
            200,
            headers: {'content-type': 'application/json'},
            request: r,
          );
        }),
      );
      addTearDown(client.dispose);
      await login(client);
      await expectLater(
        initiate(BookingRefundRepositoryImpl(client, writesEnabled: true)),
        throwsA(failure(RefundFailureKind.uncertain)),
      );
      await expectLater(
        initiate(
          BookingRefundRepositoryImpl(client, writesEnabled: true),
          reason: 'Changed intent',
        ),
        throwsA(failure(RefundFailureKind.pending)),
      );
      final receipt = await initiate(
        BookingRefundRepositoryImpl(client, writesEnabled: true),
      );
      expect(receipt.moneyReturned, false);
      expect(calls, hasLength(2));
      expect(calls[0]['p_operation_id'], calls[1]['p_operation_id']);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where((k) => k.startsWith('booking_refund_v1_')),
        isEmpty,
      );
    },
  );
  test(
    'rejected receipt never reports success and cannot switch operation',
    () async {
      final client = SupabaseClient(
        'https://example.invalid',
        'synthetic',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient(
          (r) async => http.Response(
            jsonEncode({
              ...initiation(jsonDecode(r.body)),
              'requested_amount_minor': 9999,
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: r,
          ),
        ),
      );
      addTearDown(client.dispose);
      await login(client);
      final repository = BookingRefundRepositoryImpl(
        client,
        writesEnabled: true,
      );
      await expectLater(
        initiate(repository),
        throwsA(failure(RefundFailureKind.uncertain)),
      );
      await expectLater(
        initiate(repository, reason: 'changed'),
        throwsA(failure(RefundFailureKind.pending)),
      );
    },
  );
  test(
    'canonical read after restart resolves an acknowledged initiation',
    () async {
      String? operation;
      final client = SupabaseClient(
        'https://example.invalid',
        'synthetic',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          if (r.url.path.endsWith('get_booking_refund_summary')) {
            return http.Response(
              jsonEncode(summaryJson(operation: operation)),
              200,
              headers: {'content-type': 'application/json'},
              request: r,
            );
          }
          operation = jsonDecode(r.body)['p_operation_id'];
          throw http.ClientException('Synthetic lost ACK');
        }),
      );
      addTearDown(client.dispose);
      await login(client);
      await expectLater(
        initiate(BookingRefundRepositoryImpl(client, writesEnabled: true)),
        throwsA(failure(RefundFailureKind.uncertain)),
      );
      final recovered = await BookingRefundRepositoryImpl(
        client,
      ).summary('booking', 'lounge');
      expect(recovered.requests.single.operationId, operation);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    },
  );
  test('write gate and unauthenticated actor fail before dispatch', () async {
    var calls = 0;
    final client = SupabaseClient(
      'https://example.invalid',
      'synthetic',
      httpClient: MockClient((r) async {
        calls++;
        throw StateError('must not dispatch');
      }),
    );
    addTearDown(client.dispose);
    await expectLater(
      initiate(BookingRefundRepositoryImpl(client)),
      throwsA(failure(RefundFailureKind.unavailable)),
    );
    await expectLater(
      initiate(BookingRefundRepositoryImpl(client, writesEnabled: true)),
      throwsA(failure(RefundFailureKind.denied)),
    );
    expect(calls, 0);
  });
  test(
    'gateway error is uncertain and cannot clear a dispatched journal',
    () async {
      var calls = 0;
      final client = SupabaseClient(
        'https://example.invalid',
        'synthetic',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          calls++;
          return http.Response(
            jsonEncode({
              'code': '503',
              'message': 'Synthetic gateway unavailable',
            }),
            503,
            request: r,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      await login(client);
      final repository = BookingRefundRepositoryImpl(
        client,
        writesEnabled: true,
      );
      await expectLater(
        initiate(repository),
        throwsA(failure(RefundFailureKind.uncertain)),
      );
      await expectLater(
        initiate(repository, reason: 'different'),
        throwsA(failure(RefundFailureKind.pending)),
      );
      expect(calls, 1);
      final prefs = await SharedPreferences.getInstance();
      final journal = prefs.getString(prefs.getKeys().single)!;
      expect(journal, isNot(contains('Verified synthetic return')));
      expect(journal, isNot(contains('synthetic-token')));
    },
  );
  test(
    'first definitive permission rejection can be corrected without orphan intent',
    () async {
      var calls = 0;
      final client = SupabaseClient(
        'https://example.invalid',
        'synthetic',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          calls++;
          return http.Response(
            jsonEncode(
              calls == 1
                  ? {'code': '42501', 'message': 'Synthetic permission revoked'}
                  : initiation(jsonDecode(r.body)),
            ),
            calls == 1 ? 403 : 200,
            request: r,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      await login(client);
      final repository = BookingRefundRepositoryImpl(
        client,
        writesEnabled: true,
      );
      await expectLater(
        initiate(repository),
        throwsA(failure(RefundFailureKind.denied)),
      );
      expect(
        (await initiate(repository, reason: 'corrected')).requestId,
        'request',
      );
    },
  );
  test(
    'unknown prior outcome remains pending after subsequent permission denial',
    () async {
      var calls = 0;
      final client = SupabaseClient(
        'https://example.invalid',
        'synthetic',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          if (++calls == 1) {
            throw http.ClientException('Synthetic lost response');
          }
          return http.Response(
            jsonEncode({
              'code': '42501',
              'message': 'Synthetic permission revoked',
            }),
            403,
            request: r,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      await login(client);
      final repository = BookingRefundRepositoryImpl(
        client,
        writesEnabled: true,
      );
      await expectLater(
        initiate(repository),
        throwsA(failure(RefundFailureKind.uncertain)),
      );
      await expectLater(
        initiate(repository),
        throwsA(failure(RefundFailureKind.denied)),
      );
      await expectLater(
        initiate(repository, reason: 'new intent'),
        throwsA(failure(RefundFailureKind.pending)),
      );
      expect(calls, 2);
    },
  );
  test(
    'confirmed receipt survives failed summary refresh; writes stay blocked',
    () async {
      final repository = _Repository();
      final cubit = BookingRefundCubit(repository, 'booking', 'lounge');
      addTearDown(cubit.close);
      await cubit.load();
      repository.failRefresh = true;
      await cubit.initiate('collection', 2000, 'reason', false);
      expect(cubit.state.receipt?.requestId, 'request');
      expect(cubit.state.receipt?.moneyReturned, false);
      expect(cubit.state.fresh, false);
      await cubit.initiate('collection', 2000, 'reason', false);
      expect(repository.calls, 1);
    },
  );
}

class _Repository implements BookingRefundRepository {
  bool failRefresh = false;
  int calls = 0;
  @override
  bool get writesEnabled => true;
  @override
  Future<BookingRefundSummary> summary(
    String bookingId,
    String loungeId,
  ) async {
    if (failRefresh) throw const RefundFailure(RefundFailureKind.unavailable);
    return testSummary;
  }

  @override
  Future<RefundReceipt> initiate({
    required BookingRefundSummary summary,
    required String collectionId,
    required int amountMinor,
    required String reason,
    required bool policyOverride,
  }) async {
    calls++;
    return const RefundReceipt('op', 'request', 2000);
  }

  @override
  Future<RefundReceipt> execute({
    required BookingRefundSummary summary,
    required BookingRefundRequest request,
    required String shiftId,
    required String evidence,
  }) async =>
      const RefundReceipt('op', 'request', 2000, movementId: 'reversal');
}
