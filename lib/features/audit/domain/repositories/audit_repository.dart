import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/audit_log_entity.dart';
import '../usecases/export_audit_logs_csv_usecase.dart';
import '../usecases/get_audit_logs_usecase.dart';
import '../usecases/get_timeline_logs_usecase.dart';

abstract class AuditRepository {
  Future<Either<Failure, AuditLogPaginatedResult>> getAuditLogs(
    GetAuditLogsParams params,
  );

  Future<Either<Failure, List<AuditLogEntity>>> getTimelineLogs(
    GetTimelineLogsParams params,
  );

  Future<Either<Failure, String>> exportAuditLogsCsv(
    ExportAuditLogsParams params,
  );
}
