import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:play_spot_dashboard/features/staff/data/data_source/remote/staff_remote_data_source.dart';
import 'package:play_spot_dashboard/features/staff/data/models/staff_params.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Staff mutation contract', () {
    late List<http.Request> requests;
    late SupabaseClient client;
    late StaffRemoteSourceImpl source;

    setUp(() {
      requests = <http.Request>[];
      client = SupabaseClient(
        'https://example.invalid',
        'test-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            'null',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      source = StaffRemoteSourceImpl(client);
    });

    tearDown(() async {
      await client.dispose();
    });

    test('create staff uses only create-lounge-staff Edge Function', () async {
      await source.addStaffMember(
        const AddStaffParams(
          name: 'Manager',
          email: 'manager@example.com',
          phone: '01000000000',
          password: 'password123',
          role: 'manager',
          loungeId: 'lounge-a',
        ),
      );

      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/functions/v1/create-lounge-staff');

      final payload = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(payload['role'], 'manager');
      expect(payload['lounge_id'], 'lounge-a');
    });

    test('staff profile update uses canonical RPC', () async {
      await source.updateStaffMember('staff-a', {
        'name': 'Updated',
        'phone': '01111111111',
        'role': 'manager',
      });

      expect(requests, hasLength(1));
      expect(
        requests.single.url.path,
        '/rest/v1/rpc/update_lounge_staff_member',
      );

      final payload = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(payload['p_target_user_id'], 'staff-a');
      expect(payload['p_role'], 'manager');
    });

    test('staff activation uses canonical RPC', () async {
      await source.updateStaffStatus('staff-a', false);

      expect(requests.single.url.path, '/rest/v1/rpc/set_lounge_staff_active');
      final payload = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(payload['p_target_user_id'], 'staff-a');
      expect(payload['p_is_active'], isFalse);
    });

    test('staff removal uses canonical RPC', () async {
      await source.deleteStaff('staff-a');

      expect(
        requests.single.url.path,
        '/rest/v1/rpc/remove_lounge_staff_member',
      );
      final payload = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(payload['p_target_user_id'], 'staff-a');
    });
  });
}
