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
  Future<String> uploadPromoPoster(
    Uint8List fileBytes,
    String fileName,
    String loungeId,
  );

  // Notifications & User Preferences
  Future<void> sendNotification(NotificationModel notification);
  Future<List<NotificationModel>> getNotifications({String? userId});
  Future<List<NotificationModel>> getNotificationsRpc({
    String lang = 'ar',
    int limit = 20,
    int offset = 0,
  });
  Future<PaginatedResult<NotificationModel>> getNotificationsPage({
    int page = 1,
    int pageSize = 20,
  });
  Future<void> markNotificationRead(String notificationId);
  Future<void> markAllNotificationsRead();
  RealtimeChannel subscribeToUserNotifications(
    String userId,
    void Function(NotificationModel) onNewNotification,
  );
  Future<Map<String, dynamic>?> getUserNotificationSettings(String userId);
  Future<void> updateUserNotificationSettings(
    String userId,
    Map<String, dynamic> settings,
  );
}

class MarketingRemoteDataSourceImpl implements MarketingRemoteDataSource {
  final SupabaseClient _supabase;

  MarketingRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<PromoModel>> getPromotions({
    String? loungeId,
    String? city,
  }) async {
    try {
      var query = _supabase.from('promotions').select();

      if (loungeId != null && loungeId.trim().isNotEmpty) {
        query = query.or('lounge_id.eq.${loungeId.trim()},lounge_id.is.null');
      }

      if (city != null && city.trim().isNotEmpty) {
        query = query.eq('city', city.trim());
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => PromoModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint(
        '⚠️ [MARKETING_REMOTE] getPromotions error: $e, attempting plain select fallback',
      );
      try {
        final response = await _supabase
            .from('promotions')
            .select()
            .order('created_at', ascending: false);
        return (response as List)
            .map((json) => PromoModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      } catch (e2) {
        debugPrint(
          '⚠️ [MARKETING_REMOTE] getPromotions plain fallback error: $e2',
        );
        return [];
      }
    }
  }

  @override
  Future<void> createPromotion(PromoModel promo) async {
    final colors = promo.hexColors.length >= 2
        ? promo.hexColors
        : const ['#1E88E5', '#1565C0'];

    await _supabase.rpc(
      'create_promotion',
      params: {
        'p_lounge_id': promo.loungeId,
        'p_room_id': promo.roomId,
        'p_title_ar': promo.titleAr,
        'p_title_en': promo.titleEn,
        'p_tag_ar': promo.tagAr,
        'p_tag_en': promo.tagEn,
        'p_discount_type': promo.discountType,
        'p_discount_value': promo.discountValue,
        'p_expires_at': promo.expiresAt?.toIso8601String(),
        'p_colors': colors,
        'p_icon_key': promo.iconKey,
        'p_image_url': promo.imageUrl,
        'p_deep_link': promo.deepLink,
        'p_target_audience': promo.targetAudience,
      },
    );
  }

  @override
  Future<void> updatePromotion(PromoModel promo) async {
    if (promo.id.isEmpty) {
      throw Exception('Promotion ID is required for update');
    }

    await _supabase.rpc(
      'update_promotion',
      params: {
        'p_promotion_id': promo.id,
        'p_room_id': promo.roomId,
        'p_title_ar': promo.titleAr,
        'p_title_en': promo.titleEn,
        'p_tag_ar': promo.tagAr,
        'p_tag_en': promo.tagEn,
        'p_discount_type': promo.discountType,
        'p_discount_value': promo.discountValue,
        'p_expires_at': promo.expiresAt?.toIso8601String(),
        'p_colors': promo.hexColors,
        'p_icon_key': promo.iconKey,
        'p_image_url': promo.imageUrl,
        'p_deep_link': promo.deepLink,
        'p_target_audience': promo.targetAudience,
      },
    );
  }

  @override
  Future<void> deletePromotion(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw Exception('Promotion ID is required for delete');
    }

    await _supabase.rpc(
      'delete_promotion',
      params: {'p_promotion_id': cleanId},
    );
  }

  @override
  Future<String> uploadPromoPoster(
    Uint8List fileBytes,
    String fileName,
    String loungeId,
  ) async {
    final sanitizedFileName = fileName.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) {
      throw Exception('Lounge ID is required to upload a promotion poster.');
    }
    final path =
        '$cleanLoungeId/posters/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';

    await _supabase.storage
        .from('promotion-assets')
        .uploadBinary(path, fileBytes);

    return _supabase.storage.from('promotion-assets').getPublicUrl(path);
  }

  @override
  Future<void> sendNotification(NotificationModel notification) async {
    await _supabase.rpc(
      'send_user_notification',
      params: {
        'p_user_id': notification.userId,
        'p_title_ar': notification.titleAr,
        'p_title_en': notification.titleEn,
        'p_body_ar': notification.bodyAr,
        'p_body_en': notification.bodyEn,
        'p_type': notification.type.toString().split('.').last,
        'p_metadata': <String, dynamic>{},
      },
    );
  }

  @override
  Future<List<NotificationModel>> getNotifications({String? userId}) async {
    try {
      var query = _supabase.from('notifications').select();
      if (userId != null && userId.trim().isNotEmpty) {
        query = query.eq('user_id', userId.trim());
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
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
      final response = await _supabase.rpc(
        'get_notifications',
        params: {'p_lang': lang, 'p_limit': limit, 'p_offset': offset},
      );
      if (response != null && response is List) {
        return response
            .map(
              (json) => NotificationModel.fromJson(
                Map<String, dynamic>.from(json as Map),
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint(
        '⚠️ [MARKETING_REMOTE] get_notifications RPC error: $e, falling back to direct select',
      );
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
      final response = await _supabase.rpc(
        'get_notifications_page',
        params: {'p_page': validPage, 'p_page_size': clampedPageSize},
      );

      return PaginatedResult.fromRpcResponse<NotificationModel>(
        response,
        mapper: (json) => NotificationModel.fromJson(json),
        requestedPage: validPage,
        requestedPageSize: clampedPageSize,
      );
    } catch (e) {
      debugPrint(
        '⚠️ [MARKETING_REMOTE] get_notifications_page RPC error: $e, falling back',
      );
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
    await _supabase.rpc(
      'mark_notification_read',
      params: {'p_notification_id': notificationId},
    );
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _supabase.rpc('mark_all_notifications_read');
  }

  @override
  RealtimeChannel subscribeToUserNotifications(
    String userId,
    void Function(NotificationModel) onNewNotification,
  ) {
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
  Future<Map<String, dynamic>?> getUserNotificationSettings(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('notification_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      debugPrint(
        '⚠️ [MARKETING_DATA_SOURCE] getUserNotificationSettings error: $e',
      );
      return null;
    }
  }

  @override
  Future<void> updateUserNotificationSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    final payload = {
      'user_id': userId,
      ...settings,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _supabase
        .from('notification_settings')
        .upsert(payload, onConflict: 'user_id');
  }
}
