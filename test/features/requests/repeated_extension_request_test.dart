import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:play_spot_dashboard/features/requests/data/datasources/requests_remote_data_source_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const bookingId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
  const loungeId = '11111111-2222-3333-4444-555555555555';

  test('a later extension for the same booking remains visible', () async {
    var minutes = 30;
    final client = SupabaseClient(
      'https://example.invalid',
      'fixture-public-key',
      httpClient: MockClient((request) async {
        final body = request.url.path.endsWith('get_pending_extension_requests')
            ? [
                {
                  'id': 'ext_$bookingId',
                  'booking_id': bookingId,
                  'lounge_id': loungeId,
                  'requested_minutes': minutes,
                  'extension_minutes': minutes,
                  'status': 'pending',
                  'created_at': '2026-10-16T12:00:00Z',
                },
              ]
            : [];
        return http.Response(
          jsonEncode(body),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final source = RequestsRemoteDataSourceImpl(client);
    expect(await source.getClientRequests(loungeId: loungeId), hasLength(1));
    await source.markRequestAsAttended('ext_$bookingId');
    minutes = 60;
    final repeated = await source.getClientRequests(loungeId: loungeId);
    expect(repeated, hasLength(1));
    expect(repeated.single.id, 'ext_$bookingId');
    final page = await source.getActiveLoungeRequestsPage(loungeId: loungeId);
    expect(page.items, hasLength(1));
  });
}
