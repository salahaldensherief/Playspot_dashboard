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
    final announcementId = announcement.id.isNotEmpty
        ? announcement.id
        : const Uuid().v4();

    await supabaseClient.rpc(
      'create_system_announcement',
      params: {
        'p_id': announcementId,
        'p_target_audience': announcement.targetAudience,
        'p_target_lounge_id': announcement.targetLoungeId,
        'p_title_ar': announcement.titleAr,
        'p_title_en': announcement.titleEn,
        'p_body_ar': announcement.bodyAr,
        'p_body_en': announcement.bodyEn,
        'p_type': announcement.type,
      },
    );
  }

  @override
  Future<void> deactivateAnnouncement(String id) async {
    await supabaseClient
        .from('announcements')
        .update({'is_active': false})
        .eq('id', id);
  }
}
