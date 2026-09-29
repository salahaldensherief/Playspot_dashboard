import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../repositories/audit_repository.dart';

class ExportAuditLogsParams extends Equatable {
  final String loungeId;
  final String? entityType;
  final String? entityId;
  final String? userId;
  final String? severity;
  final String? bookingId;
  final DateTime? startDate;
  final DateTime? endDate;

  const ExportAuditLogsParams({
    required this.loungeId,
    this.entityType,
    this.entityId,
    this.userId,
    this.severity,
    this.bookingId,
    this.startDate,
    this.endDate,
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
      ];
}

class ExportAuditLogsCsvUsecase {
  final AuditRepository repository;

  ExportAuditLogsCsvUsecase(this.repository);

  Future<Either<Failure, String>> call(ExportAuditLogsParams params) {
    return repository.exportAuditLogsCsv(params);
  }
}
