import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/services/lounge_owner_provisioner.dart';

void main() {
  late SupabaseClient client;
  late List<http.Request> requests;
  var status = 201;
  Map<String, dynamic> payload = {};
  setUp(() {
    requests = [];
    status = 201;
    payload = {'success': true, 'lounge_id': 'venue', 'owner_id': 'owner'};
    client = SupabaseClient(
      'https://fixture.invalid',
      'fixture-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(payload),
          status,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
  });
  tearDown(() => client.dispose());
  Future<Map<String, dynamic>> create() =>
      LoungeOwnerProvisioner(client).create(
        email: 'owner@example.invalid',
        password: 'fixture-only-password',
        ownerName: 'Owner',
        loungeName: 'Venue',
        address: 'Address',
        phone: '01234567890',
      );

  test(
    'creation uses the authenticated Edge endpoint without SQL or profile promotion',
    () async {
      expect((await create())['owner_id'], 'owner');
      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/functions/v1/create-lounge-owner');
      expect(requests.single.method, 'POST');
      final data = jsonDecode(requests.single.body) as Map;
      expect(data['address'], 'Address');
      expect(data.containsKey('role'), isFalse);
    },
  );
  for (final code in [
    'owner_permission_denied',
    'owner_email_exists',
    'owner_provisioning_unconfirmed',
  ]) {
    test('$code remains a failure without alternate mutations', () async {
      status = code == 'owner_permission_denied'
          ? 403
          : code == 'owner_email_exists'
          ? 409
          : 503;
      payload = {'error': code};
      await expectLater(
        create(),
        throwsA(
          isA<OwnerProvisioningException>().having((e) => e.code, 'code', code),
        ),
      );
      expect(requests, hasLength(1));
    });
  }
  test('incomplete success response cannot report a created lounge', () async {
    payload = {'success': true, 'lounge_id': 'venue'};
    await expectLater(create(), throwsA(isA<OwnerProvisioningException>()));
  });
}
