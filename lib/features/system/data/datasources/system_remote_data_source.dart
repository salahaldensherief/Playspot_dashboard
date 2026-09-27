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
    await supabaseClient.rpc(
      'update_app_status',
      params: {
        'p_maintenance_mode': status.isMaintenanceMode,
        'p_maintenance_message_ar': status.maintenanceMessageAr,
        'p_maintenance_message_en': status.maintenanceMessageEn,
        'p_maintenance_until': status.expectedEndTime?.toIso8601String(),
        'p_min_supported_version_android': status.minAndroidVersion,
        'p_min_supported_version_ios': status.minIosVersion,
        'p_latest_version_android': status.latestAndroidVersion,
        'p_latest_version_ios': status.latestIosVersion,
        'p_update_message_ar': status.updateMessageAr,
        'p_update_message_en': status.updateMessageEn,
        'p_store_url_android': status.storeUrlAndroid,
        'p_store_url_ios': status.storeUrlIos,
      },
    );
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
    await supabaseClient.rpc(
      'deactivate_system_announcement',
      params: {'p_announcement_id': id},
    );
  }
}
