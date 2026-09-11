import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/tournament_audit_log_entity.dart';
import '../repositories/tournament_repository.dart';

class GetAuditLogsParams extends Equatable {
  final String tournamentId;

  const GetAuditLogsParams({required this.tournamentId});

  @override
  List<Object?> get props => [tournamentId];
}

class GetAuditLogsUseCase implements UseCase<List<TournamentAuditLogEntity>, GetAuditLogsParams> {
  final TournamentRepository repository;

  GetAuditLogsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TournamentAuditLogEntity>>> call(GetAuditLogsParams params) {
    return repository.getAuditLogs(params.tournamentId);
  }
}
