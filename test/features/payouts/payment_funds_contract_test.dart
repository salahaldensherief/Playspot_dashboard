import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/payouts/data/datasources/payout_remote_data_source.dart';
import 'package:play_spot_dashboard/features/payouts/data/repositories/payout_repository_impl.dart';
import 'package:play_spot_dashboard/features/payouts/domain/entities/payment_funds_review.dart';

void main() {
  late SupabaseClient client;
  late PayoutRemoteDataSourceImpl source;
  late PayoutRepositoryImpl repository;
  late List<http.Request> calls;
  dynamic response;
  var status = 200;
  setUp(() {
    calls = [];
    status = 200;
    response = {'success': true};
    client = SupabaseClient(
      'https://example.invalid',
      'fixture-public-key',
      httpClient: MockClient((request) async {
        calls.add(request);
        return http.Response(
          jsonEncode(response),
          status,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    source = PayoutRemoteDataSourceImpl(client);
    repository = PayoutRepositoryImpl(source);
  });
  tearDown(() => client.dispose());

  test(
    'review is paginated and maps money without silently inventing zero',
    () async {
      response = [
        {
          'id': 'payment',
          'lounge_id': 'lounge',
          'booking_id': null,
          'payment_method': 'instapay',
          'amount': '100.50',
          'paid_at': '2026-10-12T12:00:00Z',
        },
      ];
      final payments = await source.getPaymentFundsReview(offset: 50);
      expect(payments.single.amount, 100.50);
      expect(calls.single.url.path, endsWith('/rpc/get_payment_funds_review'));
      expect(jsonDecode(calls.single.body), {'p_limit': 50, 'p_offset': 50});
      response[0]['amount'] = 'NaN';
      await expectLater(source.getPaymentFundsReview(), throwsFormatException);
    },
  );
  for (final holder in PaymentFundsHolder.values) {
    test(
      'custody uses explicit ${holder.name}, evidence, and no financial values from client',
      () async {
        await source.recordPaymentFundsCustody(
          paymentId: 'payment',
          holder: holder,
          evidenceReference: '  bank statement  ',
        );
        expect(
          calls.single.url.path,
          endsWith('/rpc/record_payment_funds_custody'),
        );
        expect(jsonDecode(calls.single.body), {
          'p_payment_id': 'payment',
          'p_funds_holder': holder.name,
          'p_evidence_reference': 'bank statement',
        });
      },
    );
  }
  for (final value in [
    null,
    {},
    {'success': false},
  ]) {
    test(
      'custody does not report success for malformed acknowledgement $value',
      () async {
        response = value;
        final result = await repository.recordPaymentFundsCustody(
          paymentId: 'payment',
          holder: PaymentFundsHolder.platform,
          evidenceReference: 'proof',
        );
        expect(result.isLeft(), isTrue);
      },
    );
  }
  test(
    'authorization denial propagates without direct table fallback',
    () async {
      status = 403;
      response = {'code': '42501', 'message': 'PAYOUT_ADMIN_REQUIRED'};
      expect((await repository.getPaymentFundsReview()).isLeft(), isTrue);
      expect(calls, hasLength(1));
    },
  );
  test(
    'no positive payout balance is a visible failure, not a successful action',
    () async {
      response = {'success': false, 'error': 'NO_POSITIVE_SETTLEMENT_BALANCE'};
      final result = await repository.createPayout(
        loungeId: 'lounge',
        periodStart: '2026-10-01',
        periodEnd: '2026-10-31',
      );
      expect(result.isLeft(), isTrue);
    },
  );
}
