import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/promo_model.dart';
import '../models/notification_model.dart';

abstract class MarketingRemoteDataSource {
  Future<List<PromoModel>> getPromotions({String? loungeId, String? city});
  Future<void> createPromotion(PromoModel promo);
  Future<void> deletePromotion(String id);
  Future<String> uploadPromoPoster(Uint8List fileBytes, String fileName);

  // Notifications
  Future<void> sendNotification(NotificationModel notification);
  Future<List<NotificationModel>> getNotifications();
}

class MarketingRemoteDataSourceImpl implements MarketingRemoteDataSource {
  final SupabaseClient _supabase;

  MarketingRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<PromoModel>> getPromotions({String? loungeId, String? city}) async {
    var query = _supabase.from('promotions').select();
    if (loungeId != null) query = query.eq('lounge_id', loungeId);
    
    // Add city filter if provided
    if (city != null) {
      // Assuming 'lounge' table has city and we join, or 'promotions' has city
      // Usually promos are linked to lounges, so we might need a join or the promo itself has a city scope
      // For now, let's assume 'city' is a column in 'promotions' or we filter after fetch if it's more complex
      query = query.eq('city', city);
    }

    // Filter by expiration date (expires_at > now or expires_at is null)
    final response = await query
        .or('expires_at.gt.${DateTime.now().toIso8601String()},expires_at.is.null')
        .order('created_at', ascending: false);

    return (response as List).map((json) => PromoModel.fromJson(json)).toList();
  }

  @override
  Future<void> createPromotion(PromoModel promo) async {
    final promoJson = promo.toJson();
    final payload = {
      ...promoJson,
      'title': promo.titleAr.isNotEmpty ? promo.titleAr : promo.titleEn,
      'tag': promo.tagAr.isNotEmpty ? promo.tagAr : promo.tagEn,
      'is_active': true,
    };

    // Clean up UUID fields: convert empty strings to null and remove if null
    // to prevent Supabase/Postgres from failing on invalid UUID format
    if (payload['id'] == null || (payload['id'] is String && (payload['id'] as String).isEmpty)) {
      payload.remove('id'); // Let database generate the ID
    }

    if (payload['room_id'] != null && payload['room_id'].toString().trim().isEmpty) {
      payload['room_id'] = null;
    }

    if (payload['lounge_id'] != null && payload['lounge_id'].toString().trim().isEmpty) {
      payload['lounge_id'] = null;
    }

    // Explicitly remove room_id if null to allow DB defaults or ensure clean insert
    payload.removeWhere((key, value) => value == null && (key == 'room_id' || key == 'lounge_id'));

    await _supabase.from('promotions').insert(payload);
  }

  @override
  Future<void> deletePromotion(String id) async {
    await _supabase.from('promotions').delete().eq('id', id);
  }

  @override
  Future<String> uploadPromoPoster(Uint8List fileBytes, String fileName) async {
    final path = 'posters/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _supabase.storage.from('promo-assets').uploadBinary(path, fileBytes);
    return _supabase.storage.from('promo-assets').getPublicUrl(path);
  }

  @override
  Future<void> sendNotification(NotificationModel notification) async {
    await _supabase.from('notifications').insert(notification.toJson());
  }

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final response = await _supabase.from('notifications').select().order('created_at', ascending: false);
    return (response as List).map((json) => NotificationModel.fromJson(json)).toList();
  }
}
