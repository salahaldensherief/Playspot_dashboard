import '../../domain/entities/app_status_entity.dart';

class AppStatusModel extends AppStatusEntity {
  const AppStatusModel({
    super.id,
    super.isMaintenanceMode,
    super.maintenanceMessageAr,
    super.maintenanceMessageEn,
    super.expectedEndTime,
    super.minAndroidVersion,
    super.minIosVersion,
    super.latestAndroidVersion,
    super.latestIosVersion,
    super.storeUrlAndroid,
    super.storeUrlIos,
    super.updateMessageAr,
    super.updateMessageEn,
    super.updatedAt,
  });

  factory AppStatusModel.fromJson(Map<String, dynamic> json) {
    return AppStatusModel(
      id: json['id']?.toString(),
      isMaintenanceMode: json['maintenance_mode'] as bool? ?? false,
      maintenanceMessageAr: (json['maintenance_message_ar'] ?? json['maintenance_message'])?.toString() ?? '',
      maintenanceMessageEn: (json['maintenance_message_en'] ?? json['maintenance_message'])?.toString() ?? '',
      expectedEndTime: json['maintenance_until'] != null
          ? DateTime.tryParse(json['maintenance_until'].toString())
          : null,
      minAndroidVersion: json['min_supported_version_android']?.toString() ?? '1.0.0',
      minIosVersion: json['min_supported_version_ios']?.toString() ?? '1.0.0',
      latestAndroidVersion: json['latest_version_android']?.toString() ?? '1.0.0',
      latestIosVersion: json['latest_version_ios']?.toString() ?? '1.0.0',
      storeUrlAndroid: json['store_url_android']?.toString() ?? '',
      storeUrlIos: json['store_url_ios']?.toString() ?? '',
      updateMessageAr: (json['update_message_ar'] ?? json['update_message'])?.toString() ?? '',
      updateMessageEn: (json['update_message_en'] ?? json['update_message'])?.toString() ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'maintenance_mode': isMaintenanceMode,
      'maintenance_message_ar': maintenanceMessageAr,
      'maintenance_message_en': maintenanceMessageEn,
      'maintenance_until': expectedEndTime?.toIso8601String(),
      'min_supported_version_android': minAndroidVersion,
      'min_supported_version_ios': minIosVersion,
      'latest_version_android': latestAndroidVersion,
      'latest_version_ios': latestIosVersion,
      'store_url_android': storeUrlAndroid,
      'store_url_ios': storeUrlIos,
      'update_message_ar': updateMessageAr,
      'update_message_en': updateMessageEn,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory AppStatusModel.fromEntity(AppStatusEntity entity) {
    return AppStatusModel(
      id: entity.id,
      isMaintenanceMode: entity.isMaintenanceMode,
      maintenanceMessageAr: entity.maintenanceMessageAr,
      maintenanceMessageEn: entity.maintenanceMessageEn,
      expectedEndTime: entity.expectedEndTime,
      minAndroidVersion: entity.minAndroidVersion,
      minIosVersion: entity.minIosVersion,
      latestAndroidVersion: entity.latestAndroidVersion,
      latestIosVersion: entity.latestIosVersion,
      storeUrlAndroid: entity.storeUrlAndroid,
      storeUrlIos: entity.storeUrlIos,
      updateMessageAr: entity.updateMessageAr,
      updateMessageEn: entity.updateMessageEn,
      updatedAt: entity.updatedAt,
    );
  }
}
