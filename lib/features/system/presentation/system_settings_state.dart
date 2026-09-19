import 'package:equatable/equatable.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import '../domain/entities/app_status_entity.dart';
import '../domain/entities/announcement_entity.dart';

enum SystemSettingsStatus { initial, loading, success, failure }

class SystemSettingsState extends Equatable {
  final SystemSettingsStatus status;
  final SystemSettingsStatus actionStatus;
  final AppStatusEntity appStatus;
  final List<AnnouncementEntity> announcements;
  final List<Lounge> lounges;
  final String? errorMessage;
  final String? successMessage;

  const SystemSettingsState({
    this.status = SystemSettingsStatus.initial,
    this.actionStatus = SystemSettingsStatus.initial,
    this.appStatus = const AppStatusEntity(),
    this.announcements = const [],
    this.lounges = const [],
    this.errorMessage,
    this.successMessage,
  });

  SystemSettingsState copyWith({
    SystemSettingsStatus? status,
    SystemSettingsStatus? actionStatus,
    AppStatusEntity? appStatus,
    List<AnnouncementEntity>? announcements,
    List<Lounge>? lounges,
    String? errorMessage,
    String? successMessage,
  }) {
    return SystemSettingsState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      appStatus: appStatus ?? this.appStatus,
      announcements: announcements ?? this.announcements,
      lounges: lounges ?? this.lounges,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        appStatus,
        announcements,
        lounges,
        errorMessage,
        successMessage,
      ];
}
