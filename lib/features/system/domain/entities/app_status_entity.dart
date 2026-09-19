import 'package:equatable/equatable.dart';

class AppStatusEntity extends Equatable {
  final String? id;
  final bool isMaintenanceMode;
  final String maintenanceMessageAr;
  final String maintenanceMessageEn;
  final DateTime? expectedEndTime;
  final String minAndroidVersion;
  final String minIosVersion;
  final String latestAndroidVersion;
  final String latestIosVersion;
  final String storeUrlAndroid;
  final String storeUrlIos;
  final String updateMessageAr;
  final String updateMessageEn;
  final DateTime? updatedAt;

  const AppStatusEntity({
    this.id,
    this.isMaintenanceMode = false,
    this.maintenanceMessageAr = '',
    this.maintenanceMessageEn = '',
    this.expectedEndTime,
    this.minAndroidVersion = '1.0.0',
    this.minIosVersion = '1.0.0',
    this.latestAndroidVersion = '1.0.0',
    this.latestIosVersion = '1.0.0',
    this.storeUrlAndroid = '',
    this.storeUrlIos = '',
    this.updateMessageAr = '',
    this.updateMessageEn = '',
    this.updatedAt,
  });

  AppStatusEntity copyWith({
    String? id,
    bool? isMaintenanceMode,
    String? maintenanceMessageAr,
    String? maintenanceMessageEn,
    DateTime? expectedEndTime,
    String? minAndroidVersion,
    String? minIosVersion,
    String? latestAndroidVersion,
    String? latestIosVersion,
    String? storeUrlAndroid,
    String? storeUrlIos,
    String? updateMessageAr,
    String? updateMessageEn,
    DateTime? updatedAt,
  }) {
    return AppStatusEntity(
      id: id ?? this.id,
      isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
      maintenanceMessageAr: maintenanceMessageAr ?? this.maintenanceMessageAr,
      maintenanceMessageEn: maintenanceMessageEn ?? this.maintenanceMessageEn,
      expectedEndTime: expectedEndTime ?? this.expectedEndTime,
      minAndroidVersion: minAndroidVersion ?? this.minAndroidVersion,
      minIosVersion: minIosVersion ?? this.minIosVersion,
      latestAndroidVersion: latestAndroidVersion ?? this.latestAndroidVersion,
      latestIosVersion: latestIosVersion ?? this.latestIosVersion,
      storeUrlAndroid: storeUrlAndroid ?? this.storeUrlAndroid,
      storeUrlIos: storeUrlIos ?? this.storeUrlIos,
      updateMessageAr: updateMessageAr ?? this.updateMessageAr,
      updateMessageEn: updateMessageEn ?? this.updateMessageEn,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        isMaintenanceMode,
        maintenanceMessageAr,
        maintenanceMessageEn,
        expectedEndTime,
        minAndroidVersion,
        minIosVersion,
        latestAndroidVersion,
        latestIosVersion,
        storeUrlAndroid,
        storeUrlIos,
        updateMessageAr,
        updateMessageEn,
        updatedAt,
      ];
}
