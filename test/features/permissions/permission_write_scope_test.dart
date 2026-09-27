import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/permissions/data/data_sources/permissions_remote_data_source_impl.dart';

void main() {
  test('failed lounge write propagates and never falls back to global scope', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient('https://example.invalid', 'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(jsonEncode({'message': 'denied', 'code': '42501'}), 403,
          headers: {'content-type': 'application/json'}, request: request);
      }),
    );
    final source = PermissionsRemoteSourceImpl(client);
    await expectLater(source.updateRolePermission('cashier', 'bookings.view', false, loungeId: 'lounge-a'),
      throwsA(isA<PostgrestException>()));
    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/rest/v1/lounge_role_permissions');
    expect(jsonDecode(requests.single.body)['lounge_id'], 'lounge-a');
    await client.dispose();
  });

  test('successful lounge write retains role, key and lounge', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient('https://example.invalid', 'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response('', 201, request: request);
      }),
    );
    await PermissionsRemoteSourceImpl(client).updateRolePermission(
      ' CASHIER ', 'bookings.view', false, loungeId: ' lounge-a ');
    expect(requests, hasLength(1));
    final payload = jsonDecode(requests.single.body);
    expect(payload['lounge_id'], 'lounge-a');
    expect(payload['role'], 'cashier');
    expect(payload['permission_key'], 'bookings.view');
    expect(payload['is_enabled'], false);
    await client.dispose();
  });
}
