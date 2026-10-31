import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/lounges/data/repositories/lounge_payment_settings_repository_impl.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge_payment_settings.dart';

void main() {
  test('open-time settings fail closed through the canonical RPC', () {
    final source = File(
      'lib/features/lounges/data/repositories/'
      'lounge_payment_settings_repository_impl.dart',
    ).readAsStringSync();

    expect(
      source,
      matches(RegExp(r"rpc\s*\(\s*'update_lounge_open_time_policy'\s*,")),
    );
    expect(source, isNot(contains('fallback to table update')));
    expect(
      source,
      matches(
        RegExp(
          r"updateData\s*\.\s*remove\s*\(\s*'allow_open_time_sessions'\s*\)",
        ),
      ),
    );
  });

  for (final denied in [false, true]) {
    test(
      'open-time RPC payload and fail-closed writes (denied: $denied)',
      () async {
        final requests = <http.Request>[];
        final client = SupabaseClient(
          'https://example.invalid',
          'test-key',
          httpClient: MockClient((request) async {
            requests.add(request);
            final isRpc = request.url.path.endsWith(
              '/rpc/update_lounge_open_time_policy',
            );
            return http.Response(
              denied && isRpc ? '{"message":"denied","code":"42501"}' : 'null',
              denied && isRpc ? 403 : 200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }),
        );
        addTearDown(client.dispose);
        final result = await LoungePaymentSettingsRepositoryImpl(client)
            .updatePaymentSettings(
              const LoungePaymentSettings(
                loungeId: 'lounge-contract',
                allowOpenTimeSessions: true,
                openTimeRoundingMinutes: 30,
                openTimeMinMinutes: 90,
                openTimeMaxMinutes: 300,
              ),
            );
        expect(result.isLeft(), denied);
        expect(requests, hasLength(denied ? 1 : 2));
        expect(requests.first.method, 'POST');
        expect(
          requests.first.url.path,
          '/rest/v1/rpc/update_lounge_open_time_policy',
        );
        expect(jsonDecode(requests.first.body), {
          'p_lounge_id': 'lounge-contract',
          'p_enabled': true,
          'p_rounding_minutes': 30,
          'p_minimum_minutes': 90,
          'p_max_minutes': 300,
        });
        if (!denied) {
          expect(requests.last.method, 'PATCH');
          expect(requests.last.url.path, '/rest/v1/lounges');
          final paymentFields =
              jsonDecode(requests.last.body) as Map<String, dynamic>;
          for (final key in [
            'allow_open_time_sessions',
            'open_time_rounding_minutes',
            'open_time_minimum_minutes',
            'open_time_max_minutes',
          ]) {
            expect(paymentFields, isNot(contains(key)));
          }
        }
      },
    );
  }
}
