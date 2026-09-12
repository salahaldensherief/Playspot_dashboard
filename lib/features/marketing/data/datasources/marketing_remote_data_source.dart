import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/paginated_result.dart';
import '../models/promo_model.dart';
import '../models/notification_model.dart';

abstract class MarketingRemoteDataSource {
  Future<List<PromoModel>> getPromotions({String? loungeId, String? city});
  Future<void> createPromotion(PromoModel promo);
  Future<void> deletePromotion(String id);
  Future<String> uploadPromoPoster(Uint8List fileBytes, String fileName);

  // Notifications & User Preferences
  Future<void> sendNotification(NotificationModel notification);
  Future<List<NotificationModel>> getNotifications();
  Future<List<NotificationModel>> getNotificationsRpc({String lang = 'ar', int limit = 20, int offset = 0});
  Future<PaginatedResult<NotificationModel>> getNotificationsPage({int page = 1, int pageSize = 20});
  Future<void> markNotificationRead(String notificationId);
  Future<void> markAllNotificationsRead();
  RealtimeChannel subscribeToUserNotifications(String userId, void Function(NotificationModel) onNewNotification);
  Future<Map<String, dynamic>?> getUserNotificationSettings(String userId);
  Future<void> updateUserNotificationSettings(String userId, Map<String, dynamic> settings);
}

class MarketingRemoteDataSourceImpl implements MarketingRemoteDataSource {
  final SupabaseClient _supabase;

  MarketingRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<PromoModel>> getPromotions({String? loungeId, String? city}) async {
    var query = _supabase.from('promotions').select();
    if (loungeId != null) query = query.eq('lounge_id', loungeId);
    
    if (city != null) {
      query = query.eq('city', city);
    }

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

    if (payload['id'] == null || (payload['id'] is String && (payload['id'] as String).isEmpty)) {
      payload.remove('id');
    }

    if (payload['room_id'] != null && payload['room_id'].toString().trim().isEmpty) {
      payload['room_id'] = null;
    }

    if (payload['lounge_id'] != null && payload['lounge_id'].toString().trim().isEmpty) {
      payload['lounge_id'] = null;
    }

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

  @override
  Future<List<NotificationModel>> getNotificationsRpc({
    String lang = 'ar',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc('get_notifications', params: {
        'p_lang': lang,
        'p_limit': limit,
        'p_offset': offset,
      });
      if (response != null && response is List) {
        return (response as List).map((json) => NotificationModel.fromJson(Map<String, dynamic>.from(json as Map))).toList();
      }
    } catch (e) {
      debugPrint('⚠️ [MARKETING_REMOTE] get_notifications RPC error: $e, falling back to direct select');
    }
    return getNotifications();
  }

  @override
  Future<PaginatedResult<NotificationModel>> getNotificationsPage({
    int page = 1,
    int pageSize = 20,
  }) async {
    final clampedPageSize = pageSize.clamp(1, 100);
    final validPage = page < 1 ? 1 : page;

    try {
      final response = await _supabase.rpc('get_notifications_page', params: {
        'p_page': validPage,
        'p_page_size': clampedPageSize,
      });

      return PaginatedResult.fromRpcResponse<NotificationModel>(
        response,
        mapper: (json) => NotificationModel.fromJson(json),
        requestedPage: validPage,
        requestedPageSize: clampedPageSize,
      );
    } catch (e) {
      debugPrint('⚠️ [MARKETING_REMOTE] get_notifications_page RPC error: $e, falling back');
      final list = await getNotifications();
      return PaginatedResult(
        items: list,
        totalCount: list.length,
        page: validPage,
        pageSize: clampedPageSize,
      );
    }
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _supabase.rpc('mark_notification_read', params: {
        'p_notification_id': notificationId,
      });
      return;
    } catch (e) {
      debugPrint('⚠️ [MARKETING_REMOTE] mark_notification_read RPC error: $e, fallback update');
      await _supabase.from('notifications').update({'is_read': true}).eq('id', notificationId);
    }
  }

  @override
  Future<void> markAllNotificationsRead() async {
    try {
      await _supabase.rpc('mark_all_notifications_read');
      return;
    } catch (e) {
      debugPrint('⚠️ [MARKETING_REMOTE] mark_all_notifications_read RPC error: $e, fallback update');
      await _supabase.from('notifications').update({'is_read': true});
    }
  }

  @override
  RealtimeChannel subscribeToUserNotifications(String userId, void Function(NotificationModel) onNewNotification) {
    final channel = _supabase
        .channel('public:notifications:user_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              final newModel = NotificationModel.fromJson(payload.newRecord);
              onNewNotification(newModel);
            }
          },
        )
        .subscribe();
    return channel;
  }

  @override
  Future<Map<String, dynamic>?> getUserNotificationSettings(String userId) async {
    try {
      final response = await _supabase
          .from('notification_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      debugPrint('⚠️ [MARKETING_DATA_SOURCE] getUserNotificationSettings error: $e');
      return null;
    }
  }

  @override
  Future<void> updateUserNotificationSettings(String userId, Map<String, dynamic> settings) async {
    final payload = {
      'user_id': userId,
      ...settings,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _supabase.from('notification_settings').upsert(payload, onConflict: 'user_id');
  }
}
