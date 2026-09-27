import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/lounges/domain/repositories/lounge_repository.dart';
import '../domain/entities/app_status_entity.dart';
import '../domain/entities/announcement_entity.dart';
import '../domain/usecases/get_app_status_usecase.dart';
import '../domain/usecases/update_maintenance_mode_usecase.dart';
import '../domain/usecases/update_app_versions_usecase.dart';
import '../domain/usecases/get_announcements_usecase.dart';
import '../domain/usecases/create_announcement_usecase.dart';
import '../domain/usecases/deactivate_announcement_usecase.dart';
import 'system_settings_state.dart';

class SystemSettingsCubit extends Cubit<SystemSettingsState> {
  final GetAppStatusUseCase getAppStatusUseCase;
  final UpdateMaintenanceModeUseCase updateMaintenanceModeUseCase;
  final UpdateAppVersionsUseCase updateAppVersionsUseCase;
  final GetAnnouncementsUseCase getAnnouncementsUseCase;
  final CreateAnnouncementUseCase createAnnouncementUseCase;
  final DeactivateAnnouncementUseCase deactivateAnnouncementUseCase;
  final LoungeRepository loungeRepository;

  SystemSettingsCubit({
    required this.getAppStatusUseCase,
    required this.updateMaintenanceModeUseCase,
    required this.updateAppVersionsUseCase,
    required this.getAnnouncementsUseCase,
    required this.createAnnouncementUseCase,
    required this.deactivateAnnouncementUseCase,
    required this.loungeRepository,
  }) : super(const SystemSettingsState());

  Future<void> loadData() async {
    emit(state.copyWith(status: SystemSettingsStatus.loading));

    final statusResult = await getAppStatusUseCase();
    final announcementsResult = await getAnnouncementsUseCase();
    final loungesResult = await loungeRepository.getLounges();

    AppStatusEntity appStatus = state.appStatus;
    List<AnnouncementEntity> announcements = state.announcements;
    var lounges = state.lounges;
    String? errorMsg;

    statusResult.fold(
      (failure) => errorMsg = failure.message,
      (status) => appStatus = status,
    );

    announcementsResult.fold(
      (failure) => errorMsg ??= failure.message,
      (list) => announcements = list,
    );

    loungesResult.fold(
      (_) {},
      (list) => lounges = list,
    );

    if (errorMsg != null && appStatus.id == null && announcements.isEmpty) {
      emit(state.copyWith(
        status: SystemSettingsStatus.failure,
        errorMessage: errorMsg,
      ));
    } else {
      emit(state.copyWith(
        status: SystemSettingsStatus.success,
        appStatus: appStatus,
        announcements: announcements,
        lounges: lounges,
      ));
    }
  }

  Future<void> updateMaintenanceMode({
    required bool isMaintenanceMode,
    required String maintenanceMessageAr,
    required String maintenanceMessageEn,
    DateTime? expectedEndTime,
  }) async {
    emit(state.copyWith(actionStatus: SystemSettingsStatus.loading));

    final result = await updateMaintenanceModeUseCase(
      isMaintenanceMode: isMaintenanceMode,
      maintenanceMessageAr: maintenanceMessageAr,
      maintenanceMessageEn: maintenanceMessageEn,
      expectedEndTime: expectedEndTime,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: SystemSettingsStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedStatus = state.appStatus.copyWith(
          isMaintenanceMode: isMaintenanceMode,
          maintenanceMessageAr: maintenanceMessageAr,
          maintenanceMessageEn: maintenanceMessageEn,
          expectedEndTime: expectedEndTime,
        );
        emit(state.copyWith(
          actionStatus: SystemSettingsStatus.success,
          appStatus: updatedStatus,
          successMessage: isMaintenanceMode
              ? 'تم تفعيل وضع الصيانة بنجاح!'
              : 'تم إلغاء تفعيل وضع الصيانة، النظام يعمل الآن بشكل طبيعي.',
        ));
      },
    );
  }

  Future<void> updateAppVersions(AppStatusEntity updatedStatus) async {
    emit(state.copyWith(actionStatus: SystemSettingsStatus.loading));

    final result = await updateAppVersionsUseCase(updatedStatus);

    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: SystemSettingsStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        actionStatus: SystemSettingsStatus.success,
        appStatus: updatedStatus,
        successMessage: 'تم تحديث إعدادات الإصدارات والتحديثات بنجاح.',
      )),
    );
  }

  Future<void> createAnnouncement(AnnouncementEntity announcement) async {
    emit(state.copyWith(actionStatus: SystemSettingsStatus.loading));

    final result = await createAnnouncementUseCase(announcement);

    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: SystemSettingsStatus.failure,
        errorMessage: failure.message,
      )),
      (_) async {
        emit(state.copyWith(
          actionStatus: SystemSettingsStatus.success,
          successMessage: 'تم نشر الإعلان وإرسال التنبيهات بنجاح.',
        ));
        await _refreshAnnouncements();
      },
    );
  }

  Future<void> deactivateAnnouncement(String id) async {
    emit(state.copyWith(actionStatus: SystemSettingsStatus.loading));

    final result = await deactivateAnnouncementUseCase(id);

    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: SystemSettingsStatus.failure,
        errorMessage: failure.message,
      )),
      (_) async {
        emit(state.copyWith(
          actionStatus: SystemSettingsStatus.success,
          successMessage: 'تم إنهاء الإعلان بنجاح.',
        ));
        await _refreshAnnouncements();
      },
    );
  }

  Future<void> _refreshAnnouncements() async {
    final result = await getAnnouncementsUseCase();
    result.fold(
      (_) {},
      (list) => emit(state.copyWith(announcements: list)),
    );
  }

  void clearMessages() {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }
}
