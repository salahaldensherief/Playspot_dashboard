import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/usecases/export_audit_logs_csv_usecase.dart';
import '../../domain/usecases/get_audit_logs_usecase.dart';
import '../../domain/usecases/get_timeline_logs_usecase.dart';
import '../models/audit_log_model.dart';

abstract class AuditRemoteDataSource {
  Future<List<AuditLogModel>> getAuditLogs(GetAuditLogsParams params);
  Future<List<AuditLogModel>> getTimelineLogs(GetTimelineLogsParams params);
  Future<String> exportAuditLogsCsv(ExportAuditLogsParams params);
}

class AuditRemoteDataSourceImpl implements AuditRemoteDataSource {
  final SupabaseClient supabase;
  AuditRemoteDataSourceImpl(this.supabase);

  @override
  Future<List<AuditLogModel>> getAuditLogs(GetAuditLogsParams params) async {
    final response = await supabase.rpc(
      'get_audit_logs',
      params: {
        'p_lounge_id': params.loungeId.trim().isEmpty ? null : params.loungeId,
        if (params.entityType != null &&
            params.entityType!.isNotEmpty &&
            params.entityType != 'all')
          'p_entity_type': params.entityType,
        if (params.entityId != null && params.entityId!.isNotEmpty)
          'p_entity_id': params.entityId,
        if (params.userId != null && params.userId!.isNotEmpty)
          'p_user_id': params.userId,
        if (params.severity != null &&
            params.severity!.isNotEmpty &&
            params.severity != 'all')
          'p_severity': params.severity,
        if (params.bookingId != null && params.bookingId!.isNotEmpty)
          'p_booking_id': params.bookingId,
        if (params.startDate != null)
          'p_start_date': params.startDate!.toIso8601String(),
        if (params.endDate != null)
          'p_end_date': params.endDate!.toIso8601String(),
        if (params.lastId != null && params.lastId!.isNotEmpty)
          'p_last_id': params.lastId,
        if (params.lastCreatedAt != null)
          'p_last_created_at': params.lastCreatedAt!.toIso8601String(),
        'p_limit': params.limit,
      },
    );
    if (response is! List) {
      throw const FormatException('Invalid audit response');
    }
    return response
        .map((e) => AuditLogModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<AuditLogModel>> getTimelineLogs(
    GetTimelineLogsParams params,
  ) async {
    if (params.entityType.toLowerCase() == 'room') {
      if (params.loungeId.trim().isEmpty || params.entityId.trim().isEmpty) {
        throw ArgumentError('Room audit requires lounge and room scope');
      }
      final response = await supabase
          .from('room_status_audit')
          .select(
            'id,room_id,lounge_id,booking_id,old_status,new_status,old_is_available,new_is_available,changed_by,operation,source,changed_at',
          )
          .eq('lounge_id', params.loungeId)
          .eq('room_id', params.entityId)
          .order('changed_at', ascending: false)
          .limit(params.limit);
      return response.map(AuditLogModel.fromRoomStatusJson).toList();
    }
    final isBooking = params.entityType.toLowerCase() == 'booking';
    return getAuditLogs(
      GetAuditLogsParams(
        loungeId: params.loungeId,
        entityType: isBooking ? null : params.entityType,
        entityId: isBooking ? null : params.entityId,
        bookingId: isBooking ? params.entityId : null,
        limit: params.limit,
      ),
    );
  }

  @override
  Future<String> exportAuditLogsCsv(ExportAuditLogsParams params) async {
    final logs = <AuditLogModel>[];
    AuditLogModel? cursor;
    while (true) {
      final page = await getAuditLogs(
        GetAuditLogsParams(
          loungeId: params.loungeId,
          entityType: params.entityType,
          entityId: params.entityId,
          userId: params.userId,
          severity: params.severity,
          bookingId: params.bookingId,
          startDate: params.startDate,
          endDate: params.endDate,
          lastId: cursor?.id,
          lastCreatedAt: cursor?.createdAt,
          limit: 5000,
        ),
      );
      logs.addAll(page);
      if (page.length < 5000) break;
      if (cursor?.id == page.last.id) {
        throw const FormatException('Audit export cursor did not advance');
      }
      cursor = page.last;
    }
    final buffer = StringBuffer(
      'Event ID,Date & Time,Entity Type,Entity ID,Action,Actor,Severity,Reason\r\n',
    );
    for (final log in logs) {
      buffer.writeln(
        [
          log.id,
          log.createdAt.toIso8601String(),
          log.entityType,
          log.entityId ?? '',
          log.action,
          log.actorName ?? log.actorUserId ?? 'System',
          log.severity.value,
          log.reason ?? '',
        ].map(_csvCell).join(','),
      );
    }
    return buffer.toString();
  }

  String _csvCell(String value) {
    final safe = RegExp(r'^\s*[=+@-]').hasMatch(value) ? "'$value" : value;
    return '"${safe.replaceAll('"', '""')}"';
  }
}
