import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/shifts/data/data_sources/shift_reporting_remote_helper.dart';

void main() {
  for (final rpc in [
    'get_shift_report',
    'get_cashier_performance',
    'get_lounge_comparison',
  ]) {
    late SupabaseClient client;
    late ShiftReportingRemoteHelper helper;
    Object? response = [];
    int status = 200;
    int fallbacks = 0;
    setUp(() {
      response = [];
      status = 200;
      fallbacks = 0;
      client = SupabaseClient(
        'https://fixture.invalid',
        'synthetic-public-key',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/rest/v1/rpc/$rpc');
          if (rpc == 'get_shift_report') {
            final params = jsonDecode(request.body) as Map;
            expect(params['p_lounge_id'], 'fixture');
            expect(params['p_cashier_id'], 'cashier');
            expect(
              params['p_start_date'],
              DateTime(2026, 10, 1).toIso8601String(),
            );
          }
          return http.Response(
            jsonEncode(response),
            status,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      helper = ShiftReportingRemoteHelper(client);
    });
    tearDown(() async => client.dispose());
    Future<Object> load() async {
      if (rpc == 'get_shift_report') {
        return helper.getShiftReport(
          loungeId: 'fixture',
          cashierId: 'cashier',
          startDate: DateTime(2026, 10, 1),
          fallbackFetcher: ({loungeId}) async {
            fallbacks++;
            return [];
          },
        );
      }
      if (rpc == 'get_cashier_performance') {
        return helper.getCashierPerformance(loungeId: 'fixture');
      }
      return helper.getLoungeComparison();
    }

    test(
      '$rpc propagates permission failure without empty or unfiltered substitution',
      () async {
        status = 403;
        response = {'message': 'synthetic permission denial', 'code': '42501'};
        await expectLater(load(), throwsA(isA<PostgrestException>()));
        expect(fallbacks, 0);
      },
    );
    test('$rpc preserves a valid empty report', () async {
      expect(await load(), isEmpty);
    });
    test(
      '$rpc rejects malformed response instead of an empty report',
      () async {
        response = null;
        await expectLater(load(), throwsA(isA<FormatException>()));
        expect(fallbacks, 0);
      },
    );
  }
}
