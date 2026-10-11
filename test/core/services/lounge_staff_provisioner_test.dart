import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/services/lounge_staff_provisioner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const body = {
    'email': 'staff@example.invalid',
    'password': 'secret-test',
    'full_name': 'Fixture',
    'phone': '',
    'lounge_id': 'venue',
    'role': 'cashier',
  };
  late SupabaseClient client;
  late List<Map<String, dynamic>> requests;
  String? actor;
  bool malformed = false;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    requests = [];
    actor = 'actor-a';
    malformed = false;
    client = SupabaseClient(
      'https://fixture.invalid',
      'synthetic-key',
      httpClient: MockClient((request) async {
        requests.add(jsonDecode(request.body) as Map<String, dynamic>);
        final recovery = requests.last['recovery_user_id'];
        return http.Response(
          jsonEncode(
            malformed
                ? null
                : recovery == null
                ? {
                    'provisioning_confirmed': false,
                    'recovery_user_id': 'staff-id',
                  }
                : {'success': true, 'user_id': recovery, 'role': 'cashier'},
          ),
          malformed || recovery != null ? 201 : 503,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
  tearDown(() => client.dispose());
  LoungeStaffProvisioner provisioner() =>
      LoungeStaffProvisioner(client, actorId: () => actor);
  test(
    'unconfirmed finalization survives a new service instance and retry does not recreate Auth',
    () async {
      await expectLater(provisioner().create(body), throwsA(isA<Exception>()));
      await provisioner().create(body);
      expect(requests.first.containsKey('recovery_user_id'), isFalse);
      expect(requests.last['recovery_user_id'], 'staff-id');
      final saved = await const FlutterSecureStorage().readAll();
      expect(
        saved.values.any((value) => value.contains('secret-test')),
        isFalse,
      );
      expect(
        saved.values.every(
          (value) =>
              jsonDecode(value) is Map && (jsonDecode(value) as Map).isEmpty,
        ),
        isTrue,
      );
    },
  );
  test('changed original details are refused before another request', () async {
    await expectLater(provisioner().create(body), throwsA(isA<Exception>()));
    await expectLater(
      provisioner().create({...body, 'full_name': 'Changed'}),
      throwsA(isA<Exception>()),
    );
    expect(requests, hasLength(1));
  });
  test('another actor never receives the saved recovery identity', () async {
    await expectLater(provisioner().create(body), throwsA(isA<Exception>()));
    actor = 'actor-b';
    await expectLater(provisioner().create(body), throwsA(isA<Exception>()));
    expect(requests.last.containsKey('recovery_user_id'), isFalse);
  });
  test(
    'malformed successful HTTP response cannot complete staff creation',
    () async {
      malformed = true;
      await expectLater(provisioner().create(body), throwsA(isA<Exception>()));
    },
  );
}
