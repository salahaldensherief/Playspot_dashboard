import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/paginated_result.dart';
import '../models/promo_model.dart';
import '../models/notification_model.dart';

abstract class MarketingRemoteDataSource {
  Future<List<PromoModel>> getPromotions({String? loungeId, String? city});
  Future<void> createPromotion(PromoModel promo);
  Future<void> updatePromotion(PromoModel promo);
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
    try {
      var query = _supabase.from('promotions').select();
      
      if (loungeId != null && loungeId.trim().isNotEmpty) {
        query = query.or('lounge_id.eq.${loungeId.trim()},lounge_id.is.null');
      }
      
      if (city != null && city.trim().isNotEmpty) {
        query = query.eq('city', city.trim());
      }

      final response = await query.order('created_at', ascending: false);
      
      return (response as List).map((json) => PromoModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      debugPrint('⚠️ [MARKETING_REMOTE] getPromotions error: $e, attempting plain select fallback');
      try {
        final response = await _supabase.from('promotions').select().order('created_at', ascending: false);
        return (response as List).map((json) => PromoModel.fromJson(Map<String, dynamic>.from(json))).toList();
      } catch (e2) {
        debugPrint('⚠️ [MARKETING_REMOTE] getPromotions plain fallback error: $e2');
        return [];
      }
    }
  }

  @override
  Future<void> createPromotion(PromoModel promo) async {
    final promoJson = promo.toJson();
    final payload = <String, dynamic>{
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
    debugPrint('🟢 [MARKETING_REMOTE] Successfully inserted promo into promotions table with image_url: ${promo.imageUrl}');

    // Try publish_promotion RPC as secondary step if loungeId exists
    if (promo.loungeId != null && promo.loungeId!.isNotEmpty) {
      try {
        debugPrint('🚀 [MARKETING_REMOTE] Calling publish_promotion RPC for lounge: ${promo.loungeId}');
        await _supabase.rpc('publish_promotion', params: {
          'p_expires_at': promo.expiresAt?.toIso8601String(),
          'p_lounge_id': promo.loungeId,
          'p_room_id': promo.roomId,
          'p_tag_ar': promo.tagAr.isNotEmpty ? promo.tagAr : promo.tag,
          'p_tag_en': promo.tagEn.isNotEmpty ? promo.tagEn : promo.tag,
          'p_title_ar': promo.titleAr.isNotEmpty ? promo.titleAr : promo.titleEn,
          'p_title_en': promo.titleEn.isNotEmpty ? promo.titleEn : promo.titleAr,
        });
      } catch (e) {
        debugPrint('ℹ️ [MARKETING_REMOTE] publish_promotion RPC notice: $e');
      }
    }
  }

  @override
  Future<void> updatePromotion(PromoModel promo) async {
    if (promo.id.isEmpty) {
      throw Exception('Promotion ID is required for update');
    }

    final payload = <String, dynamic>{
      'title_ar': promo.titleAr,
      'title_en': promo.titleEn,
      'tag_ar': promo.tagAr,
      'tag_en': promo.tagEn,
      'title': promo.titleAr.isNotEmpty ? promo.titleAr : promo.titleEn,
      'tag': promo.tagAr.isNotEmpty ? promo.tagAr : promo.tagEn,
      'image_url': promo.imageUrl,
      'deep_link': promo.deepLink,
      'expires_at': promo.expiresAt?.toIso8601String(),
      'room_id': promo.roomId,
      'is_room_specific': promo.isRoomSpecific,
      'target_audience': promo.targetAudience,
      'icon_key': promo.iconKey,
      'colors': promo.hexColors,
    };

    await _supabase.from('promotions').update(payload).eq('id', promo.id);
    debugPrint('🟢 [MARKETING_REMOTE] Successfully updated promo ${promo.id} with image_url: ${promo.imageUrl}');
  }

  @override
  Future<void> deletePromotion(String id) async {
    try {
      await _supabase.from('promotions').delete().eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('permission denied')) {
        throw Exception('عفواً، لا تملك الصلاحية الكافية لحذف هذا العرض (RLS Restricted).');
      }
      rethrow;
    }
  }

  @override
  Future<String> uploadPromoPoster(Uint8List fileBytes, String fileName) async {
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'posters/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
    
    // 1. Try promotion-assets bucket (newly created bucket)
    try {
      await _supabase.storage.from('promotion-assets').uploadBinary(path, fileBytes);
      return _supabase.storage.from('promotion-assets').getPublicUrl(path);
    } catch (e) {
      debugPrint('⚠️ [MARKETING_REMOTE] promotion-assets bucket upload error ($e), attempting promo-assets...');
    }

    // 2. Fallback to promo-assets bucket
    try {
      await _supabase.storage.from('promo-assets').uploadBinary(path, fileBytes);
      return _supabase.storage.from('promo-assets').getPublicUrl(path);
    } catch (e) {
      debugPrint('⚠️ [MARKETING_REMOTE] promo-assets bucket upload error ($e), attempting lounge-assets...');
    }

    // 3. Fallback to lounge-assets bucket
    try {
      await _supabase.storage.from('lounge-assets').uploadBinary(path, fileBytes);
      return _supabase.storage.from('lounge-assets').getPublicUrl(path);
    } catch (e) {
      debugPrint('⚠️ [MARKETING_REMOTE] lounge-assets bucket upload error ($e), attempting tournament-assets...');
    }

    // 4. Fallback to tournament-assets bucket
    try {
      await _supabase.storage.from('tournament-assets').uploadBinary(path, fileBytes);
      return _supabase.storage.from('tournament-assets').getPublicUrl(path);
    } catch (e) {
      debugPrint('⚠️ [MARKETING_REMOTE] All storage buckets unavailable: $e');
    }

    // Return empty string gracefully if no storage buckets exist on Supabase
    debugPrint('⚠️ [MARKETING_REMOTE] No storage buckets exist on Supabase. Returning empty image url gracefully.');
    return '';
  }

  @override
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _supabase.rpc('send_notification', params: {
        'p_user_id': notification.userId,
        'p_title_ar': notification.titleAr,
        'p_title_en': notification.titleEn,
        'p_body_ar': notification.bodyAr,
        'p_body_en': notification.bodyEn,
        'p_type': notification.type.toString().split('.').last,
      });
      return;
    } catch (e) {
      debugPrint('⚠️ [MARKETING_REMOTE] send_notification RPC error: $e, attempting direct insert fallback');
      try {
        await _supabase.from('notifications').insert(notification.toJson());
      } on PostgrestException catch (pe) {
        if (pe.code == '42501' || pe.message.contains('permission denied')) {
          throw Exception('عفواً، يتطلب إرسال الإشعارات صلاحيات المسؤول الفائق (Super Admin).');
        }
        rethrow;
      }
    }
  }

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _supabase.from('notifications').select().order('created_at', ascending: false);
      return (response as List).map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('⚠️ [MARKETING_REMOTE] getNotifications query error: $e');
      return [];
    }
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
        return response.map((json) => NotificationModel.fromJson(Map<String, dynamic>.from(json as Map))).toList();
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
