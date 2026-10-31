import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/file_download_helper.dart';
import '../domain/usecases/export_audit_logs_csv_usecase.dart';
import '../domain/usecases/get_audit_logs_usecase.dart';
import 'audit_state.dart';

class AuditCubit extends Cubit<AuditState> {
  int _generation = 0;
  String? _loungeScope;
  final GetAuditLogsUsecase getAuditLogsUsecase;
  final ExportAuditLogsCsvUsecase exportAuditLogsCsvUsecase;

  AuditCubit({
    required this.getAuditLogsUsecase,
    required this.exportAuditLogsCsvUsecase,
  }) : super(const AuditState());

  Future<void> loadAuditLogs({
    required String loungeId,
    bool refresh = true,
  }) async {
    if (isClosed || (state.status == AuditStatus.loading && !refresh)) return;
    final generation = ++_generation;
    _loungeScope = loungeId.trim();

    emit(
      state.copyWith(
        status: AuditStatus.loading,
        clearError: true,
        isLoadingMore: false,
        exportSuccess: false,
        logs: refresh ? [] : state.logs,
      ),
    );

    final params = GetAuditLogsParams(
      loungeId: loungeId,
      entityType: state.selectedEntityType,
      severity: state.selectedSeverity,
      userId: state.selectedUserId,
      bookingId: state.searchBookingId,
      startDate: state.startDate,
      endDate: state.endDate,
      limit: 20,
    );

    final result = await getAuditLogsUsecase(params);
    if (isClosed || generation != _generation) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuditStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (paginated) => emit(
        state.copyWith(
          status: AuditStatus.success,
          logs: paginated.logs,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> loadMoreLogs({required String loungeId}) async {
    if (isClosed ||
        _loungeScope != loungeId.trim() ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.logs.isEmpty) {
      return;
    }
    final generation = _generation;

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    final lastLog = state.logs.last;

    final params = GetAuditLogsParams(
      loungeId: loungeId,
      entityType: state.selectedEntityType,
      severity: state.selectedSeverity,
      userId: state.selectedUserId,
      bookingId: state.searchBookingId,
      startDate: state.startDate,
      endDate: state.endDate,
      lastId: lastLog.id,
      lastCreatedAt: lastLog.createdAt,
      limit: 20,
    );

    final result = await getAuditLogsUsecase(params);
    if (isClosed || generation != _generation) return;

    result.fold(
      (failure) => emit(
        state.copyWith(isLoadingMore: false, errorMessage: failure.message),
      ),
      (paginated) => emit(
        state.copyWith(
          isLoadingMore: false,
          logs: [...state.logs, ...paginated.logs],
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  void updateFilters({
    required String loungeId,
    String? entityType,
    String? severity,
    String? userId,
    String? bookingId,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEntityType = false,
    bool clearSeverity = false,
    bool clearUserId = false,
    bool clearBookingId = false,
    bool clearDates = false,
  }) {
    if (isClosed) return;
    emit(
      state.copyWith(
        selectedEntityType: entityType,
        selectedSeverity: severity,
        selectedUserId: userId,
        searchBookingId: bookingId,
        startDate: startDate,
        endDate: endDate,
        clearEntityType: clearEntityType,
        clearSeverity: clearSeverity,
        clearUserId: clearUserId,
        clearBookingId: clearBookingId,
        clearDates: clearDates,
      ),
    );

    loadAuditLogs(loungeId: loungeId, refresh: true);
  }

  void resetFilters({required String loungeId}) {
    if (isClosed) return;
    emit(
      state.copyWith(
        clearEntityType: true,
        clearSeverity: true,
        clearUserId: true,
        clearBookingId: true,
        clearDates: true,
      ),
    );

    loadAuditLogs(loungeId: loungeId, refresh: true);
  }

  Future<void> exportCsv({required String loungeId}) async {
    if (isClosed || state.isExporting) return;
    final generation = _generation;

    emit(
      state.copyWith(isExporting: true, exportSuccess: false, clearError: true),
    );

    final params = ExportAuditLogsParams(
      loungeId: loungeId,
      entityType: state.selectedEntityType,
      severity: state.selectedSeverity,
      userId: state.selectedUserId,
      bookingId: state.searchBookingId,
      startDate: state.startDate,
      endDate: state.endDate,
    );

    final result = await exportAuditLogsCsvUsecase(params);
    if (isClosed) return;
    if (generation != _generation) {
      emit(state.copyWith(isExporting: false));
      return;
    }

    result.fold(
      (failure) => emit(
        state.copyWith(isExporting: false, errorMessage: failure.message),
      ),
      (csvContent) {
        final filename = 'audit_logs_${DateTime.now().millisecondsSinceEpoch}';
        FileDownloadHelper.downloadCsv(csvContent, filename);
        emit(state.copyWith(isExporting: false, exportSuccess: true));
      },
    );
  }
}
