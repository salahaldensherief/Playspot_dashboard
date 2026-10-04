import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/shifts/data/data_sources/shift_remote_data_source_impl.dart';

void main() {
  for (final mode in [
    'own',
    'manager',
    'denied',
    'missing-cashier',
    'missing-scope',
    'unconfirmed',
  ]) {
    test('blind close preserves stored cashier and scope: $mode', () async {
      final calls = <http.Request>[];
      final actor = mode == 'own' ? 'cashier' : 'manager';
      final client = SupabaseClient(
        'https://example.invalid',
        'synthetic-key',
        httpClient: MockClient((request) async {
          calls.add(request);
          Object body;
          int status = 200;
          if (request.url.path.endsWith('/rpc/blind_close_shift')) {
            if (mode == 'unconfirmed') {
              body = {'success': false, 'shift_id': 'shift', 'status': 'open'};
            } else {
              body = {
                'success': true,
                'shift_id': 'shift',
                'status': 'closed',
                'actual_cash_counted': 100,
              };
            }
          } else if (mode == 'denied') {
            status = 403;
            body = {'code': '42501', 'message': 'Denied'};
          } else {
            body = {
              'id': 'shift',
              'lounge_id': 'venue',
              'cashier_id': mode == 'missing-cashier' ? null : 'cashier',
              'starting_cash': 0,
              'start_time': '2026-10-04T10:00:00Z',
              'status': calls.length > 2 ? 'closed' : 'open',
            };
          }
          return http.Response(
            jsonEncode(body),
            status,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      await client.auth.recoverSession(
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
      final future = ShiftRemoteDataSourceImpl(client).closeShift(
        'shift',
        100,
        null,
        loungeId: mode == 'missing-scope' ? null : 'venue',
      );
      if (mode == 'denied') {
        await expectLater(future, throwsA(isA<PostgrestException>()));
      } else if (mode == 'missing-scope') {
        await expectLater(future, throwsArgumentError);
      } else if (mode == 'missing-cashier' || mode == 'unconfirmed') {
        await expectLater(future, throwsFormatException);
      } else {
        final result = await future;
        expect(result.cashierId, 'cashier');
        expect(result.id, 'shift');
        expect(result.status, 'closed');
      }
      final writes = calls.where((r) => r.method == 'POST').toList();
      if (['denied', 'missing-scope', 'missing-cashier'].contains(mode)) {
        expect(writes, isEmpty);
      } else {
        expect(writes, hasLength(1));
        expect(jsonDecode(writes.single.body), {
          'p_shift_id': 'shift',
          'p_cashier_id': 'cashier',
          'p_counted_cash': 100.0,
          'p_notes': null,
        });
      }
      for (final read in calls.where((r) => r.method == 'GET')) {
        expect(read.url.queryParameters['id'], 'eq.shift');
        expect(read.url.queryParameters['lounge_id'], 'eq.venue');
      }
    });
  }
}
