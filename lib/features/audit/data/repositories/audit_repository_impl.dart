import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../../domain/repositories/audit_repository.dart';
import '../../domain/usecases/export_audit_logs_csv_usecase.dart';
import '../../domain/usecases/get_audit_logs_usecase.dart';
import '../../domain/usecases/get_timeline_logs_usecase.dart';
import '../datasources/audit_remote_datasource.dart';
import '../audit_failure_mapper.dart';

class AuditRepositoryImpl implements AuditRepository {
  final AuditRemoteDataSource remoteDataSource;

  AuditRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, AuditLogPaginatedResult>> getAuditLogs(
    GetAuditLogsParams params,
  ) async {
    try {
      final logs = await remoteDataSource.getAuditLogs(params);
      final bool hasMore = logs.length >= params.limit;
      String? nextId;
      DateTime? nextCreatedAt;

      if (logs.isNotEmpty) {
        nextId = logs.last.id;
        nextCreatedAt = logs.last.createdAt;
      }

      return Right(
        AuditLogPaginatedResult(
          logs: logs,
          hasMore: hasMore,
          nextCursorId: nextId,
          nextCursorCreatedAt: nextCreatedAt,
        ),
      );
    } catch (e) {
      return Left(auditFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<AuditLogEntity>>> getTimelineLogs(
    GetTimelineLogsParams params,
  ) async {
    try {
      final logs = await remoteDataSource.getTimelineLogs(params);
      return Right(logs);
    } catch (e) {
      return Left(auditFailure(e));
    }
  }

  @override
  Future<Either<Failure, String>> exportAuditLogsCsv(
    ExportAuditLogsParams params,
  ) async {
    try {
      final csv = await remoteDataSource.exportAuditLogsCsv(params);
      return Right(csv);
    } catch (e) {
      return Left(auditFailure(e));
    }
  }
}
