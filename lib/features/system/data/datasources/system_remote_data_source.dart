import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/app_status_model.dart';
import '../models/announcement_model.dart';

abstract class SystemRemoteDataSource {
  Future<AppStatusModel> getAppStatus();
  Future<void> updateAppStatus(AppStatusModel status);
  Future<List<AnnouncementModel>> getAnnouncements();
  Future<void> createAnnouncement(AnnouncementModel announcement);
  Future<void> deactivateAnnouncement(String id);
}

class SystemRemoteDataSourceImpl implements SystemRemoteDataSource {
  final SupabaseClient supabaseClient;

  SystemRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<AppStatusModel> getAppStatus() async {
    final response = await supabaseClient
        .from('app_status')
        .select()
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return const AppStatusModel(
        isMaintenanceMode: false,
        maintenanceMessageAr: '',
        maintenanceMessageEn: '',
        minAndroidVersion: '1.0.0',
        minIosVersion: '1.0.0',
        latestAndroidVersion: '1.0.0',
        latestIosVersion: '1.0.0',
      );
    }

    return AppStatusModel.fromJson(response);
  }

  @override
  Future<void> updateAppStatus(AppStatusModel status) async {
    final payload = status.toJson();
    if (status.id != null && status.id!.isNotEmpty) {
      await supabaseClient.from('app_status').upsert(payload, onConflict: 'id');
    } else {
      final existing = await supabaseClient
          .from('app_status')
          .select('id')
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        payload['id'] = existing['id'];
        await supabaseClient
            .from('app_status')
            .update(payload)
            .eq('id', existing['id']);
      } else {
        await supabaseClient.from('app_status').insert(payload);
      }
    }
  }

  @override
  Future<List<AnnouncementModel>> getAnnouncements() async {
    final response = await supabaseClient
        .from('announcements')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    final announcementId = announcement.id.isNotEmpty ? announcement.id : const Uuid().v4();
    final updatedEntity = announcement.copyWith(id: announcementId);
    final payloadWithId = AnnouncementModel.fromEntity(updatedEntity).toJson();

    // 1. Save to database table announcements
    await supabaseClient.from('announcements').insert(payloadWithId);

    // 2. Determine FCM topic matching the Edge Function expectation
    String topic = 'all_users';
    if (announcement.targetAudience == 'lounge_owners') {
      topic = 'owners';
    } else if (announcement.targetAudience == 'specific_lounge' && announcement.targetLoungeId != null) {
      topic = 'lounge_${announcement.targetLoungeId}';
    }

    // 3. Invoke Supabase Edge Function 'send-system-announcement'
    try {
      await supabaseClient.functions.invoke(
        'send-system-announcement',
        body: {
          'topic': topic,
          'title': announcement.titleAr,
          'body': announcement.bodyAr,
          'announcement_id': announcementId,
          'data': {
            'type': announcement.type,
            'target_audience': announcement.targetAudience,
          },
        },
      );
    } catch (_) {
      // Edge function push notification trigger handled gracefully
    }
  }

  @override
  Future<void> deactivateAnnouncement(String id) async {
    await supabaseClient
        .from('announcements')
        .update({'is_active': false})
        .eq('id', id);
  }
}
