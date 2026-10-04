import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/users/data/datasources/moderation_remote_data_source.dart';

void main() {
  for (final operation in [
    'approve_lounge_ban_request',
    'approve_global_ban_request',
    'reject_ban_request',
    'suspend_lounge',
  ]) {
    test('$operation sends the verified live named parameters', () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://fixture.invalid',
        'fixture-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            'null',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final source = ModerationRemoteDataSourceImpl(client);
      switch (operation) {
        case 'approve_lounge_ban_request':
          await source.approveLoungeBanRequest(
            'request',
            adminNotes: 'reviewed',
          );
        case 'approve_global_ban_request':
          await source.approveGlobalBanRequest(
            'request',
            adminNotes: 'reviewed',
          );
        case 'reject_ban_request':
          await source.rejectBanRequest('request', adminNotes: 'reviewed');
        case 'suspend_lounge':
          await source.suspendLounge('venue', reason: 'reviewed');
      }
      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/rest/v1/rpc/$operation');
      expect(
        jsonDecode(requests.single.body),
        operation == 'suspend_lounge'
            ? {'p_lounge_id': 'venue', 'p_reason': 'reviewed'}
            : {'p_request_id': 'request', 'p_admin_notes': 'reviewed'},
      );
    });
  }
  for (final pending in [true, false]) {
    for (final code in ['42501', 'PGRST202']) {
      test('moderation list pending=$pending preserves $code failure', () async {
        var requests = 0;
        final client = SupabaseClient(
          'https://fixture.invalid',
          'fixture-key',
          httpClient: MockClient((request) async {
            requests++;
            return http.Response(
              jsonEncode({
                'code': code,
                'message': 'denied or missing contract',
              }),
              code == '42501' ? 403 : 404,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        addTearDown(client.dispose);
        final source = ModerationRemoteDataSourceImpl(client);
        await expectLater(
          pending
              ? source.getPendingBanRequests()
              : source.getLoungeBanRequests('venue'),
          throwsA(
            isA<PostgrestException>().having(
              (error) => error.code,
              'code',
              code,
            ),
          ),
        );
        expect(
          requests,
          1,
          reason:
              'No fallback or silent success after authorization/schema failure',
        );
      });
    }
  }
}
