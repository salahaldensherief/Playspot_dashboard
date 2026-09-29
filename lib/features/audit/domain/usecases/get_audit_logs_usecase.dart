import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/audit_log_entity.dart';
import '../repositories/audit_repository.dart';

class GetAuditLogsParams extends Equatable {
  final String loungeId;
  final String? entityType;
  final String? entityId;
  final String? userId;
  final String? severity;
  final String? bookingId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? lastId;
  final DateTime? lastCreatedAt;
  final int limit;

  const GetAuditLogsParams({
    required this.loungeId,
    this.entityType,
    this.entityId,
    this.userId,
    this.severity,
    this.bookingId,
    this.startDate,
    this.endDate,
    this.lastId,
    this.lastCreatedAt,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [
        loungeId,
        entityType,
        entityId,
        userId,
        severity,
        bookingId,
        startDate,
        endDate,
        lastId,
        lastCreatedAt,
        limit,
      ];
}

class GetAuditLogsUsecase {
  final AuditRepository repository;

  GetAuditLogsUsecase(this.repository);

  Future<Either<Failure, AuditLogPaginatedResult>> call(GetAuditLogsParams params) {
    return repository.getAuditLogs(params);
  }
}
