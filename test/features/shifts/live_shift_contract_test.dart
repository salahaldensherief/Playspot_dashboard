import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/shifts/data/data_sources/shift_remote_data_source_impl.dart';
import 'package:play_spot_dashboard/features/shifts/data/models/live_shift_overview_model.dart';
import 'package:play_spot_dashboard/features/requests/data/datasources/requests_remote_data_source_impl.dart';
import 'package:play_spot_dashboard/features/requests/data/datasources/requests_fallback_fetcher.dart';

void main() {
  test(
    'maps canonical shift time and expected cash without inventing absent counts',
    () {
      final overview = LiveShiftOverviewModel.fromJson({
        'has_active_shift': true,
        'shift_id': 's',
        'opened_at': '2026-10-02T10:00:00Z',
        'starting_cash': 100,
        'expected_cash': 250,
        'digital_sales': 80,
      });
      expect(overview.startTime, DateTime.utc(2026, 10, 2, 10));
      expect(overview.startingCash, 100);
      expect(overview.cashInDrawer, 250);
      expect(overview.digitalPayments, 80);
      expect(overview.activeSessions, isNull);
      expect(overview.closedBookings, isNull);
    },
  );

  for (final code in ['42501', 'P0001', 'PGRST301']) {
    for (final operation in [
      'shift',
      'requests-page',
      'requests-list',
      'extension',
      'fallback',
    ]) {
      test(
        '$operation propagates $code denial without a secondary lookup',
        () async {
          final calls = <http.Request>[];
          final client = SupabaseClient(
            'https://example.invalid',
            'test-key',
            httpClient: MockClient((request) async {
              calls.add(request);
              return http.Response(
                jsonEncode({
                  'code': code,
                  'message': 'Not authorized for this lounge.',
                }),
                403,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }),
          );
          addTearDown(client.dispose);
          final future = switch (operation) {
            'shift' => ShiftRemoteDataSourceImpl(
              client,
            ).getLoungeLiveShiftOverview('lounge-1'),
            'requests-page' => RequestsRemoteDataSourceImpl(
              client,
            ).getActiveLoungeRequestsPage(loungeId: 'lounge-1'),
            'requests-list' => RequestsRemoteDataSourceImpl(
              client,
            ).getClientRequests(loungeId: 'lounge-1'),
            'extension' => RequestsFallbackFetcher(
              client,
            ).fetchPendingExtensionRequests('lounge-1'),
            _ => RequestsFallbackFetcher(
              client,
            ).fetchFallbackRequests('lounge-1'),
          };
          await expectLater(future, throwsA(isA<PostgrestException>()));
          expect(calls, hasLength(1));
        },
      );
    }
  }

  test(
    'authoritative no-active-shift response is not contradicted by a table fallback',
    () async {
      final calls = <http.Request>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'test-key',
        httpClient: MockClient((request) async {
          calls.add(request);
          return http.Response(
            '{"has_active_shift":false}',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      expect(
        (await ShiftRemoteDataSourceImpl(
          client,
        ).getLoungeLiveShiftOverview('lounge-1')).hasActiveShift,
        isFalse,
      );
      expect(calls, hasLength(1));
      expect(jsonDecode(calls.single.body), {'p_lounge_id': 'lounge-1'});
    },
  );

  test('null shift response is an error, not a closed lounge', () async {
    final client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      httpClient: MockClient(
        (request) async => http.Response(
          'null',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      ),
    );
    addTearDown(client.dispose);
    await expectLater(
      ShiftRemoteDataSourceImpl(client).getLoungeLiveShiftOverview('lounge-1'),
      throwsFormatException,
    );
  });
}
