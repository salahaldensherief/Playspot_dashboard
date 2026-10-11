import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/canteen/data/datasources/canteen_remote_datasource_impl.dart';
import 'package:play_spot_dashboard/features/pricing/data/datasources/pricing_remote_datasource.dart';
import 'package:play_spot_dashboard/features/pricing/data/models/pricing_rule_model.dart';

void main() {
  test(
    'canteen read failures propagate instead of becoming empty success',
    () async {
      final client = SupabaseClient(
        'https://example.invalid',
        'test-key',
        httpClient: MockClient(
          (request) async => http.Response(
            '{"message":"Denied","code":"42501"}',
            403,
            headers: {'content-type': 'application/json'},
            request: request,
          ),
        ),
      );
      addTearDown(client.dispose);
      final source = CanteenRemoteDataSourceImpl(client);
      for (final request in [
        () => source.getCombos(loungeId: 'lounge'),
        () => source.getUpsellRules(loungeId: 'lounge'),
        () => source.getUpsellConversions(loungeId: 'lounge'),
        () => source.getLowStockAlerts(loungeId: 'lounge'),
      ]) {
        await expectLater(request(), throwsA(isA<PostgrestException>()));
      }
    },
  );
  test(
    'combo and upsell removal uses the permanent archive contract',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'test-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          final payload = jsonDecode(request.body) as Map;
          return http.Response(
            jsonEncode({
              'success': true,
              'id': payload['p_id'],
              'kind': payload['p_kind'],
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final source = CanteenRemoteDataSourceImpl(client);
      await source.deleteCombo('combo');
      await source.deleteUpsellRule('rule');
      expect(requests.map((r) => r.method), ['POST', 'POST']);
      for (final request in requests)
        expect(request.url.path, '/rest/v1/rpc/archive_canteen_catalogue_item');
      expect(jsonDecode(requests[0].body), {
        'p_kind': 'combo',
        'p_id': 'combo',
      });
      expect(jsonDecode(requests[1].body), {
        'p_kind': 'upsell_rule',
        'p_id': 'rule',
      });
    },
  );
  test(
    'catalogue reload excludes deleted rows while retaining ordinary inactive offers',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'test-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          expect(request.url.queryParameters['deleted_at'], 'is.null');
          expect(request.url.queryParameters.containsKey('is_active'), false);
          return http.Response(
            jsonEncode([
              {
                'id': 'disabled',
                'lounge_id': 'lounge',
                'name_ar': 'Disabled',
                'price': 10,
                'is_active': false,
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final source = CanteenRemoteDataSourceImpl(client);
      expect(
        (await source.getCombos(loungeId: 'lounge')).single.isActive,
        false,
      );
      expect(
        (await source.getUpsellRules(loungeId: 'lounge')).single.isActive,
        false,
      );
      expect(requests, hasLength(2));
    },
  );
  test(
    'archive failure stays visible instead of pretending a successful deletion',
    () async {
      var denied = false;
      final client = SupabaseClient(
        'https://example.invalid',
        'test-key',
        httpClient: MockClient(
          (request) async => http.Response(
            denied
                ? '{"code":"42501","message":"Denied"}'
                : '{"success":false}',
            denied ? 403 : 200,
            headers: {'content-type': 'application/json'},
            request: request,
          ),
        ),
      );
      addTearDown(client.dispose);
      final source = CanteenRemoteDataSourceImpl(client);
      await expectLater(
        source.deleteCombo('combo'),
        throwsA(isA<FormatException>()),
      );
      denied = true;
      await expectLater(
        source.deleteUpsellRule('rule'),
        throwsA(isA<PostgrestException>()),
      );
    },
  );
  test(
    'pricing conflict request includes dates and does not hide server failure',
    () async {
      final requests = <http.Request>[];
      var deny = false;
      final client = SupabaseClient(
        'https://example.invalid',
        'test-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            deny ? '{"message":"Denied","code":"42501"}' : '[]',
            deny ? 403 : 200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final source = PricingRemoteDataSourceImpl(client);
      final rule = PricingRuleModel(
        id: 'rule',
        loungeId: 'lounge',
        nameAr: 'Test',
        nameEn: 'Test',
        startTime: '22:00',
        endTime: '02:00',
        startDate: DateTime(2026, 10, 12),
        endDate: DateTime(2026, 10, 13),
        createdAt: DateTime(2026),
      );
      expect(await source.checkRuleConflicts(rule), isEmpty);
      expect(
        requests.single.url.path,
        '/rest/v1/rpc/check_pricing_rule_conflicts_v2',
      );
      final payload = jsonDecode(requests.single.body) as Map;
      expect(payload['p_start_date'], '2026-10-12');
      expect(payload['p_end_date'], '2026-10-13');
      deny = true;
      await expectLater(
        source.checkRuleConflicts(rule),
        throwsA(isA<PostgrestException>()),
      );
      expect(requests, hasLength(2));
    },
  );
}
