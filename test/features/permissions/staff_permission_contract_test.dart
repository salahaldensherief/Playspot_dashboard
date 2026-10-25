import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:play_spot_dashboard/features/permissions/data/data_sources/permissions_remote_data_source_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('owner staff permission reads effective server values', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'success': true,
            'lounge_id': 'lounge-a',
            'target_user_id': 'staff-a',
            'permissions': [
              {'permission_key': 'billing_checkout', 'is_enabled': false},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    final permissions = await PermissionsRemoteSourceImpl(
      client,
    ).getStaffPermissions('staff-a', loungeId: 'lounge-a');
    expect(permissions.single.key, 'billing_checkout');
    expect(permissions.single.isEnabled, false);
    expect(
      requests.single.url.path,
      '/rest/v1/rpc/get_lounge_staff_permissions',
    );
    expect(jsonDecode(requests.single.body)['p_target_user_id'], 'staff-a');
    expect(jsonDecode(requests.single.body)['p_lounge_id'], 'lounge-a');
    await client.dispose();
  });

  test(
    'staff permission success requires a matching canonical response',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'test-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'success': true,
              'lounge_id': 'lounge-a',
              'target_user_id': 'staff-a',
              'permission_key': 'billing_checkout',
              'is_enabled': true,
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      await PermissionsRemoteSourceImpl(client).setStaffPermission(
        loungeId: 'lounge-a',
        staffId: 'staff-a',
        permissionKey: 'billing_checkout',
        isEnabled: true,
      );
      expect(requests.single.url.path, '/rest/v1/rpc/set_staff_permission');
      expect(jsonDecode(requests.single.body)['p_lounge_id'], 'lounge-a');
      await client.dispose();
    },
  );

  test('null or mismatched permission response is not success', () async {
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
    await expectLater(
      PermissionsRemoteSourceImpl(client).setStaffPermission(
        loungeId: 'lounge-a',
        staffId: 'staff-a',
        permissionKey: 'billing_checkout',
        isEnabled: true,
      ),
      throwsA(isA<FormatException>()),
    );
    await client.dispose();
  });
}
