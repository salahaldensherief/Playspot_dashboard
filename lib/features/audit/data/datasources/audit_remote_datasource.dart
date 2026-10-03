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
    try {
      final rpcParams = <String, dynamic>{
        'p_lounge_id': params.loungeId,
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
      };

      try {
        final response = await supabase.rpc(
          'get_audit_logs',
          params: rpcParams,
        );
        if (response is List) {
          return response
              .map(
                (e) =>
                    AuditLogModel.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
        }
      } catch (_) {
        // Fall back to table query
      }

      var query = supabase
          .from('audit_logs')
          .select('*, profiles(full_name, role)');

      if (params.loungeId.isNotEmpty) {
        query = query.eq('lounge_id', params.loungeId);
      }
      if (params.entityType != null &&
          params.entityType!.isNotEmpty &&
          params.entityType != 'all') {
        query = query.eq('entity_type', params.entityType!);
      }
      if (params.entityId != null && params.entityId!.isNotEmpty) {
        query = query.eq('entity_id', params.entityId!);
      }
      if (params.userId != null && params.userId!.isNotEmpty) {
        query = query.eq('actor_user_id', params.userId!);
      }
      if (params.severity != null &&
          params.severity!.isNotEmpty &&
          params.severity != 'all') {
        query = query.eq('severity', params.severity!);
      }
      if (params.startDate != null) {
        query = query.gte('created_at', params.startDate!.toIso8601String());
      }
      if (params.endDate != null) {
        query = query.lte('created_at', params.endDate!.toIso8601String());
      }
      if (params.lastCreatedAt != null) {
        query = query.lt('created_at', params.lastCreatedAt!.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(params.limit);
      return (response as List)
          .map(
            (e) => AuditLogModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
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
    try {
      if (params.entityType.toLowerCase() == 'booking') {
        try {
          final res = await supabase.rpc(
            'get_booking_timeline_for_customer',
            params: {'p_booking_id': params.entityId},
          );
          if (res is List) {
            return res
                .map(
                  (e) => AuditLogModel.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList();
          }
        } catch (_) {
          try {
            final res = await supabase.rpc(
              'get_booking_timeline',
              params: {'p_booking_id': params.entityId},
            );
            if (res is List) {
              return res
                  .map(
                    (e) => AuditLogModel.fromJson(
                      Map<String, dynamic>.from(e as Map),
                    ),
                  )
                  .toList();
            }
          } catch (_) {
            // Fall through
          }
        }
      }

      return await getAuditLogs(
        GetAuditLogsParams(
          loungeId: params.loungeId,
          entityType: params.entityType,
          entityId: params.entityId,
          limit: params.limit,
        ),
      );
    } catch (_) {
      return [];
    }
  }

  @override
  Future<String> exportAuditLogsCsv(ExportAuditLogsParams params) async {
    try {
      try {
        final res = await supabase.rpc(
          'export_audit_logs_csv',
          params: {
            'p_lounge_id': params.loungeId,
            if (params.entityType != null && params.entityType != 'all')
              'p_entity_type': params.entityType,
            if (params.entityId != null) 'p_entity_id': params.entityId,
            if (params.userId != null) 'p_user_id': params.userId,
            if (params.severity != null && params.severity != 'all')
              'p_severity': params.severity,
            if (params.bookingId != null) 'p_booking_id': params.bookingId,
            if (params.startDate != null)
              'p_start_date': params.startDate!.toIso8601String(),
            if (params.endDate != null)
              'p_end_date': params.endDate!.toIso8601String(),
            'p_limit': 5000,
          },
        );
        if (res is String && res.isNotEmpty) {
          return res;
        }
      } catch (_) {
        // Fall back
      }

      final logs = await getAuditLogs(
        GetAuditLogsParams(
          loungeId: params.loungeId,
          entityType: params.entityType,
          entityId: params.entityId,
          userId: params.userId,
          severity: params.severity,
          bookingId: params.bookingId,
          startDate: params.startDate,
          endDate: params.endDate,
          limit: 5000,
        ),
      );

      final StringBuffer buffer = StringBuffer();
      buffer.writeln(
        'Event ID,Date & Time,Entity Type,Entity ID,Action,Actor,Severity,Reason',
      );

      for (final log in logs) {
        final sanitizedReason = (log.reason ?? '')
            .replaceAll(',', ' ')
            .replaceAll('\n', ' ');
        final sanitizedActor = (log.actorName ?? log.actorUserId ?? 'System')
            .replaceAll(',', ' ');
        buffer.writeln(
          '${log.id},${log.createdAt.toIso8601String()},${log.entityType},${log.entityId ?? ''},${log.action},$sanitizedActor,${log.severity.value},$sanitizedReason',
        );
      }

      return buffer.toString();
    } catch (_) {
      return 'Event ID,Date & Time,Entity Type,Entity ID,Action,Actor,Severity,Reason\n';
    }
  }
}
