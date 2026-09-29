import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pricing_quote_model.dart';
import '../models/pricing_rule_model.dart';

abstract class PricingRemoteDataSource {
  Future<List<PricingRuleModel>> getPricingRules({required String loungeId});

  Future<PricingRuleModel> savePricingRule(PricingRuleModel rule);

  Future<void> deletePricingRule(String id);

  Future<List<PricingRuleModel>> checkRuleConflicts(PricingRuleModel rule);

  Future<PricingQuoteModel> quoteBookingPrice({
    required String roomId,
    required String date,
    required String startTime,
    required String endTime,
    String playMode = 'single',
    int extraControllers = 0,
    String? couponCode,
  });

  Future<List<Map<String, dynamic>>> getRoomSlotsWithPrices({
    required String roomId,
    required String date,
  });

  Future<Map<String, dynamic>> getLoungePriceRange({
    required String loungeId,
  });
}

class PricingRemoteDataSourceImpl implements PricingRemoteDataSource {
  final SupabaseClient supabase;

  PricingRemoteDataSourceImpl(this.supabase);

  @override
  Future<List<PricingRuleModel>> getPricingRules({required String loungeId}) async {
    try {
      final response = await supabase
          .from('pricing_rules')
          .select('*')
          .eq('lounge_id', loungeId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => PricingRuleModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<PricingRuleModel> savePricingRule(PricingRuleModel rule) async {
    final payload = rule.toJson();
    if (rule.id.isNotEmpty) {
      final response = await supabase
          .from('pricing_rules')
          .update(payload)
          .eq('id', rule.id)
          .select()
          .single();
      return PricingRuleModel.fromJson(Map<String, dynamic>.from(response));
    } else {
      final response =
          await supabase.from('pricing_rules').insert(payload).select().single();
      return PricingRuleModel.fromJson(Map<String, dynamic>.from(response));
    }
  }

  @override
  Future<void> deletePricingRule(String id) async {
    await supabase.from('pricing_rules').delete().eq('id', id);
  }

  @override
  Future<List<PricingRuleModel>> checkRuleConflicts(PricingRuleModel rule) async {
    try {
      final response = await supabase.rpc(
        'check_pricing_rule_conflicts',
        params: {
          'p_lounge_id': rule.loungeId,
          if (rule.spaceTypeId != null) 'p_space_type_id': rule.spaceTypeId,
          if (rule.roomId != null) 'p_room_id': rule.roomId,
          'p_start_time': rule.startTime,
          'p_end_time': rule.endTime,
          'p_days': rule.daysOfWeek,
          if (rule.id.isNotEmpty) 'p_exclude_rule_id': rule.id,
        },
      );
      if (response is List) {
        return response
            .map((e) => PricingRuleModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      // Fallback local conflict check against table if RPC not present
      final allRules = await getPricingRules(loungeId: rule.loungeId);
      final conflicts = allRules.where((existing) {
        if (rule.id.isNotEmpty && existing.id == rule.id) return false;
        if (!existing.isActive) return false;

        final daysOverlap =
            existing.daysOfWeek.any((day) => rule.daysOfWeek.contains(day));
        if (!daysOverlap) return false;

        final timeOverlap = (rule.startTime.compareTo(existing.endTime) < 0) &&
            (rule.endTime.compareTo(existing.startTime) > 0);
        return timeOverlap;
      }).toList();

      return conflicts;
    }
    return [];
  }

  @override
  Future<PricingQuoteModel> quoteBookingPrice({
    required String roomId,
    required String date,
    required String startTime,
    required String endTime,
    String playMode = 'single',
    int extraControllers = 0,
    String? couponCode,
  }) async {
    try {
      final response = await supabase.rpc(
        'quote_booking_price',
        params: {
          'p_room_id': roomId,
          'p_date': date,
          'p_start': startTime,
          'p_end': endTime,
          'p_play_mode': playMode,
          'p_extra_controllers': extraControllers,
          'p_coupon_code':
              (couponCode != null && couponCode.isNotEmpty) ? couponCode : null,
        },
      );
      if (response is Map) {
        return PricingQuoteModel.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (_) {
      // Safe fallback quote
    }

    return const PricingQuoteModel(
      segments: [],
      roomSubtotal: 0.0,
      extraControllersAmount: 0.0,
      discountAmount: 0.0,
      total: 0.0,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getRoomSlotsWithPrices({
    required String roomId,
    required String date,
  }) async {
    try {
      final response = await supabase.rpc(
        'get_room_slots_with_prices',
        params: {
          'p_room_id': roomId,
          'p_date': date,
        },
      );
      if (response is List) {
        return response.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<Map<String, dynamic>> getLoungePriceRange({
    required String loungeId,
  }) async {
    try {
      final response = await supabase.rpc(
        'get_lounge_price_range',
        params: {'p_lounge_id': loungeId},
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (_) {}
    return {'min_hourly_rate': 0, 'max_hourly_rate': 0, 'currency': 'EGP'};
  }
}
