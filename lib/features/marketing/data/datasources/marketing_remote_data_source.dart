import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/promo_model.dart';
import '../models/notification_model.dart';

abstract class MarketingRemoteDataSource {
  Future<List<PromoModel>> getPromotions({String? loungeId});
  Future<void> createPromotion(PromoModel promo);
  Future<void> deletePromotion(String id);

  // Notifications
  Future<void> sendNotification(NotificationModel notification);
  Future<List<NotificationModel>> getNotifications();
}

class MarketingRemoteDataSourceImpl implements MarketingRemoteDataSource {
  final SupabaseClient _supabase;

  MarketingRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<PromoModel>> getPromotions({String? loungeId}) async {
    var query = _supabase.from('promotions').select();
    if (loungeId != null) query = query.eq('lounge_id', loungeId);
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => PromoModel.fromJson(json)).toList();
  }

  @override
  Future<void> createPromotion(PromoModel promo) async {
    await _supabase.from('promotions').insert(promo.toJson());
  }

  @override
  Future<void> deletePromotion(String id) async {
    await _supabase.from('promotions').delete().eq('id', id);
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
