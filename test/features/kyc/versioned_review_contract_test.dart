import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/kyc/data/datasources/kyc_remote_data_source_impl.dart';
import 'package:play_spot_dashboard/features/kyc/domain/entities/kyc_request.dart';

void main() {
  test(
    'review sends exact request and revision, never owner-wide decision',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'test-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({'success': true, 'request_id': 'review-1'}),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      await KycRemoteDataSourceImpl(client).reviewKyc(
        requestId: 'review-1',
        revision: 3,
        approve: false,
        notes: 'Missing details',
      );
      expect(requests.single.url.path, '/rest/v1/rpc/review_lounge_request');
      expect(jsonDecode(requests.single.body), {
        'p_request_id': 'review-1',
        'p_revision': 3,
        'p_approve': false,
        'p_notes': 'Missing details',
      });
    },
  );

  for (final result in [
    {'success': false, 'request_id': 'review-1'},
    {'success': true, 'request_id': 'different'},
  ]) {
    test('invalid decision result cannot report success: $result', () async {
      final client = SupabaseClient(
        'https://example.invalid',
        'test-key',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode(result),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          ),
        ),
      );
      addTearDown(client.dispose);
      await expectLater(
        KycRemoteDataSourceImpl(
          client,
        ).reviewKyc(requestId: 'review-1', revision: 3, approve: true),
        throwsFormatException,
      );
    });
  }

  test('review model preserves frozen lounge data and revision', () {
    final request = KycRequest.fromJson({
      'id': 'review-1',
      'owner_id': 'owner-1',
      'lounge_id': 'lounge-2',
      'revision': 3,
      'owner_name': 'Owner',
      'lounge_name': 'Venue',
      'snapshot': {
        'lounge': {'address': 'Address'},
        'rooms': [
          {'name': 'Room'},
        ],
      },
    });
    expect(request.submissionId, 'review-1');
    expect(request.revision, 3);
    expect(request.userId, 'owner-1');
    expect(request.loungeId, 'lounge-2');
    expect((request.snapshot['lounge'] as Map)['address'], 'Address');
  });
}
