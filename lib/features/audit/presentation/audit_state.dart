import 'package:equatable/equatable.dart';
import '../domain/entities/audit_log_entity.dart';

enum AuditStatus { initial, loading, success, failure }

class AuditState extends Equatable {
  final AuditStatus status;
  final List<AuditLogEntity> logs;
  final bool hasMore;
  final bool isLoadingMore;
  final String? selectedEntityType;
  final String? selectedSeverity;
  final String? selectedUserId;
  final String? searchBookingId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? errorMessage;
  final bool isExporting;
  final bool exportSuccess;

  const AuditState({
    this.status = AuditStatus.initial,
    this.logs = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.selectedEntityType,
    this.selectedSeverity,
    this.selectedUserId,
    this.searchBookingId,
    this.startDate,
    this.endDate,
    this.errorMessage,
    this.isExporting = false,
    this.exportSuccess = false,
  });

  AuditState copyWith({
    AuditStatus? status,
    List<AuditLogEntity>? logs,
    bool? hasMore,
    bool? isLoadingMore,
    String? selectedEntityType,
    String? selectedSeverity,
    String? selectedUserId,
    String? searchBookingId,
    DateTime? startDate,
    DateTime? endDate,
    String? errorMessage,
    bool? isExporting,
    bool? exportSuccess,
    bool clearEntityType = false,
    bool clearSeverity = false,
    bool clearUserId = false,
    bool clearBookingId = false,
    bool clearDates = false,
  }) {
    return AuditState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedEntityType:
          clearEntityType ? null : (selectedEntityType ?? this.selectedEntityType),
      selectedSeverity:
          clearSeverity ? null : (selectedSeverity ?? this.selectedSeverity),
      selectedUserId: clearUserId ? null : (selectedUserId ?? this.selectedUserId),
      searchBookingId:
          clearBookingId ? null : (searchBookingId ?? this.searchBookingId),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      errorMessage: errorMessage ?? this.errorMessage,
      isExporting: isExporting ?? this.isExporting,
      exportSuccess: exportSuccess ?? this.exportSuccess,
    );
  }

  @override
  List<Object?> get props => [
        status,
        logs,
        hasMore,
        isLoadingMore,
        selectedEntityType,
        selectedSeverity,
        selectedUserId,
        searchBookingId,
        startDate,
        endDate,
        errorMessage,
        isExporting,
        exportSuccess,
      ];
}
