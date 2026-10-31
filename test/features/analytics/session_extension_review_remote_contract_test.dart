import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:play_spot_dashboard/features/analytics/data/datasources/session_operations_remote_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const bookingId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  test(
    'approve extension sends canonical booking UUID and requires success',
    () async {
      final calls = <http.Request>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'fixture-public-key',
        httpClient: MockClient((request) async {
          calls.add(request);
          return http.Response(
            jsonEncode({'success': true, 'status': 'approved'}),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);

      await SessionOperationsRemoteHelper(
        client,
      ).reviewExtensionRequest(bookingId: 'ext_$bookingId', isApproved: true);
      expect(calls, hasLength(1));
      expect(calls.single.url.path, '/rest/v1/rpc/approve_booking_extension');
      expect(jsonDecode(calls.single.body), {
        'p_booking_id': bookingId,
        'p_additional_cost': null,
      });
    },
  );

  test(
    'malformed extension booking ID cannot return success without a call',
    () async {
      final calls = <http.Request>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'fixture-public-key',
        httpClient: MockClient((request) async {
          calls.add(request);
          return http.Response(
            jsonEncode({'success': true}),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);

      for (final invalid in ['not-a-booking', 'prefix_$bookingId-extra']) {
        await expectLater(
          SessionOperationsRemoteHelper(
            client,
          ).reviewExtensionRequest(bookingId: invalid, isApproved: true),
          throwsFormatException,
        );
      }
      expect(calls, isEmpty);
    },
  );

  test('rejected or missing backend acknowledgement is a failure', () async {
    for (final body in [
      {'success': false},
      {'status': 'approved'},
      <String, dynamic>{},
    ]) {
      final client = SupabaseClient(
        'https://example.invalid',
        'fixture-public-key',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode(body),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      try {
        await expectLater(
          SessionOperationsRemoteHelper(
            client,
          ).reviewExtensionRequest(bookingId: bookingId, isApproved: true),
          throwsFormatException,
        );
      } finally {
        client.dispose();
      }
    }
  });

  test('reject extension sends canonical booking ID and reason', () async {
    final calls = <http.Request>[];
    final client = SupabaseClient(
      'https://example.invalid',
      'fixture-public-key',
      httpClient: MockClient((request) async {
        calls.add(request);
        return http.Response(
          jsonEncode({'success': true, 'status': 'rejected'}),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    await SessionOperationsRemoteHelper(client).reviewExtensionRequest(
      bookingId: bookingId,
      isApproved: false,
      reason: 'No available time',
    );
    expect(calls.single.url.path, '/rest/v1/rpc/reject_booking_extension');
    expect(jsonDecode(calls.single.body), {
      'p_booking_id': bookingId,
      'p_reason': 'No available time',
    });
  });
}
