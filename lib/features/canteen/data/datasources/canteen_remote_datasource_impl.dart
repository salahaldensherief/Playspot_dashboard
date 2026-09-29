import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/canteen_combo_model.dart';
import '../models/low_stock_alert_model.dart';
import '../models/upsell_conversion_model.dart';
import '../models/upsell_rule_model.dart';
import 'canteen_remote_datasource.dart';

class CanteenRemoteDataSourceImpl implements CanteenRemoteDataSource {
  final SupabaseClient supabase;

  CanteenRemoteDataSourceImpl(this.supabase);

  @override
  Future<List<CanteenComboModel>> getCombos({required String loungeId}) async {
    try {
      final response = await supabase
          .from('canteen_combos')
          .select('''
            *,
            canteen_combo_items (
              combo_id,
              extra_id,
              quantity,
              extras (
                id,
                name_ar,
                name_en,
                price,
                cost_price,
                image_url
              )
            )
          ''')
          .eq('lounge_id', loungeId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => CanteenComboModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<CanteenComboModel> saveCombo(CanteenComboModel combo) async {
    final payload = combo.toJson();
    String comboId = combo.id;

    if (comboId.isNotEmpty) {
      await supabase
          .from('canteen_combos')
          .update(payload)
          .eq('id', comboId);

      // Re-sync items: delete existing and reinsert
      await supabase
          .from('canteen_combo_items')
          .delete()
          .eq('combo_id', comboId);
    } else {
      final insertRes = await supabase
          .from('canteen_combos')
          .insert(payload)
          .select('id')
          .single();
      comboId = insertRes['id'].toString();
    }

    // Insert combo components
    if (combo.items.isNotEmpty) {
      final itemsPayload = combo.items.map((item) {
        return {
          'combo_id': comboId,
          'extra_id': item.extraId,
          'quantity': item.quantity,
        };
      }).toList();

      await supabase.from('canteen_combo_items').insert(itemsPayload);
    }

    // Fetch and return the newly saved combo with full relations
    final response = await supabase
        .from('canteen_combos')
        .select('''
          *,
          canteen_combo_items (
            combo_id,
            extra_id,
            quantity,
            extras (
              id,
              name_ar,
              name_en,
              price,
              cost_price,
              image_url
            )
          )
        ''')
        .eq('id', comboId)
        .single();

    return CanteenComboModel.fromJson(Map<String, dynamic>.from(response));
  }

  @override
  Future<void> deleteCombo(String id) async {
    await supabase.from('canteen_combos').delete().eq('id', id);
  }

  @override
  Future<List<UpsellRuleModel>> getUpsellRules({required String loungeId}) async {
    try {
      final response = await supabase
          .from('upsell_rules')
          .select('''
            *,
            extras (
              id,
              name_ar,
              name_en,
              price,
              image_url
            ),
            canteen_combos (
              id,
              name_ar,
              name_en,
              price,
              image_url
            )
          ''')
          .eq('lounge_id', loungeId)
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => UpsellRuleModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<UpsellRuleModel> saveUpsellRule(UpsellRuleModel rule) async {
    final payload = rule.toJson();
    String ruleId = rule.id;

    if (ruleId.isNotEmpty) {
      await supabase
          .from('upsell_rules')
          .update(payload)
          .eq('id', ruleId);
    } else {
      final insertRes = await supabase
          .from('upsell_rules')
          .insert(payload)
          .select('id')
          .single();
      ruleId = insertRes['id'].toString();
    }

    final response = await supabase
        .from('upsell_rules')
        .select('''
          *,
          extras (
            id,
            name_ar,
            name_en,
            price,
            image_url
          ),
          canteen_combos (
            id,
            name_ar,
            name_en,
            price,
            image_url
          )
        ''')
        .eq('id', ruleId)
        .single();

    return UpsellRuleModel.fromJson(Map<String, dynamic>.from(response));
  }

  @override
  Future<void> deleteUpsellRule(String id) async {
    await supabase.from('upsell_rules').delete().eq('id', id);
  }

  @override
  Future<List<UpsellConversionModel>> getUpsellConversions({required String loungeId}) async {
    try {
      final response = await supabase
          .from('canteen_upsell_conversion_v')
          .select('*')
          .eq('lounge_id', loungeId);

      return (response as List)
          .map((e) => UpsellConversionModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<LowStockAlertModel>> getLowStockAlerts({required String loungeId}) async {
    try {
      final response = await supabase
          .from('canteen_low_stock_alerts_v')
          .select('*')
          .eq('lounge_id', loungeId);

      return (response as List)
          .map((e) => LowStockAlertModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
