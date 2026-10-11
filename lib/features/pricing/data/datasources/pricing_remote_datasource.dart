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
  Future<List<PricingRuleModel>> getPricingRules({
    required String loungeId,
  }) async {
    final response = await supabase
        .from('pricing_rules')
        .select('*')
        .eq('lounge_id', loungeId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (e) => PricingRuleModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
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
    final response = await supabase.rpc(
      'check_pricing_rule_conflicts_v2',
      params: {
        'p_lounge_id': rule.loungeId,
        if (rule.spaceTypeId != null) 'p_space_type_id': rule.spaceTypeId,
        if (rule.roomId != null) 'p_room_id': rule.roomId,
        'p_start_time': rule.startTime,
        'p_end_time': rule.endTime,
        'p_days': rule.daysOfWeek,
        if (rule.id.isNotEmpty) 'p_exclude_rule_id': rule.id,
        'p_start_date': rule.startDate?.toIso8601String().split('T').first,
        'p_end_date': rule.endDate?.toIso8601String().split('T').first,
      },
    );
    if (response is! List) {
      throw const FormatException('Invalid pricing conflict response');
    }
    return response
        .map((e) => PricingRuleModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
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
    if (response is! Map) {
      throw const FormatException('Invalid pricing quote response');
    }
    return PricingQuoteModel.fromJson(Map<String, dynamic>.from(response));
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
      if (response is! List) {
        throw const FormatException('Invalid priced slots response');
      }
      final rows =
          response.length == 1 && response.first is List
          ? response.first as List
          : response;
      return rows
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getLoungePriceRange({
    required String loungeId,
  }) async {
    final response = await supabase.rpc(
      'get_lounge_price_range',
      params: {'p_lounge_id': loungeId},
    );
    if (response is! Map) {
      throw const FormatException('Invalid lounge price range response');
    }
    return Map<String, dynamic>.from(response);
  }
}
