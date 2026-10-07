import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/canteen/data/datasources/canteen_remote_datasource_impl.dart';
import 'package:play_spot_dashboard/features/pricing/data/datasources/pricing_remote_datasource.dart';
import 'package:play_spot_dashboard/features/pricing/data/models/pricing_rule_model.dart';

void main() {
  test('canteen read failures propagate instead of becoming empty success', () async {
    final client = SupabaseClient('https://example.invalid', 'test-key',
      httpClient: MockClient((request) async => http.Response(
        '{"message":"Denied","code":"42501"}',403,
        headers: {'content-type':'application/json'})));
    addTearDown(client.dispose);
    final source = CanteenRemoteDataSourceImpl(client);
    for (final request in [
      () => source.getCombos(loungeId:'lounge'),
      () => source.getUpsellRules(loungeId:'lounge'),
      () => source.getUpsellConversions(loungeId:'lounge'),
      () => source.getLowStockAlerts(loungeId:'lounge'),
    ]) {
      await expectLater(request(),throwsA(isA<PostgrestException>()));
    }
  });
  test('combo and upsell removal deactivate the catalogue and preserve sales', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient('https://example.invalid','test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response('null',200,headers:{'content-type':'application/json'});
      }));
    addTearDown(client.dispose);
    final source = CanteenRemoteDataSourceImpl(client);
    await source.deleteCombo('combo');
    await source.deleteUpsellRule('rule');
    expect(requests.map((r)=>r.method),['PATCH','PATCH']);
    expect(requests[0].url.path,'/rest/v1/canteen_combos');
    expect(requests[1].url.path,'/rest/v1/upsell_rules');
    for (final request in requests) {
      expect(jsonDecode(request.body),{'is_active':false});
    }
  });
  test('pricing conflict request includes dates and does not hide server failure', () async {
    final requests = <http.Request>[];
    var deny = false;
    final client = SupabaseClient('https://example.invalid','test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(deny ? '{"message":"Denied","code":"42501"}' : '[]',
          deny ? 403 : 200,headers:{'content-type':'application/json'});
      }));
    addTearDown(client.dispose);
    final source = PricingRemoteDataSourceImpl(client);
    final rule = PricingRuleModel(id:'rule',loungeId:'lounge',nameAr:'Test',nameEn:'Test',
      startTime:'22:00',endTime:'02:00',startDate:DateTime(2026,10,12),endDate:DateTime(2026,10,13),createdAt:DateTime(2026));
    expect(await source.checkRuleConflicts(rule),isEmpty);
    expect(requests.single.url.path,'/rest/v1/rpc/check_pricing_rule_conflicts_v2');
    final payload = jsonDecode(requests.single.body) as Map;
    expect(payload['p_start_date'],'2026-10-12');
    expect(payload['p_end_date'],'2026-10-13');
    deny=true;
    await expectLater(source.checkRuleConflicts(rule),throwsA(isA<PostgrestException>()));
    expect(requests,hasLength(2));
  });
}
