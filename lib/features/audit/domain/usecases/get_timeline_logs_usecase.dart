import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/audit_log_entity.dart';
import '../repositories/audit_repository.dart';

class GetTimelineLogsParams extends Equatable {
  final String loungeId;
  final String entityType;
  final String entityId;
  final int limit;

  const GetTimelineLogsParams({
    required this.loungeId,
    required this.entityType,
    required this.entityId,
    this.limit = 50,
  });

  @override
  List<Object?> get props => [loungeId, entityType, entityId, limit];
}

class GetTimelineLogsUsecase {
  final AuditRepository repository;

  GetTimelineLogsUsecase(this.repository);

  Future<Either<Failure, List<AuditLogEntity>>> call(GetTimelineLogsParams params) {
    return repository.getTimelineLogs(params);
  }
}
