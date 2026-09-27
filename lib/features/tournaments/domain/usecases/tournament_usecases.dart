import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../../../../core/utils/paginated_result.dart';
import '../entities/tournament_audit_log_entity.dart';
import '../entities/tournament_entity.dart';
import '../entities/tournament_match_entity.dart';
import '../entities/tournament_prize_entity.dart';
import '../repositories/tournament_repository.dart';


class GetTournamentsParams extends Equatable {
  final double? latitude;
  final double? longitude;
  final String? loungeId;
  final String? status;
  final int limit;
  final int offset;

  const GetTournamentsParams({
    this.latitude,
    this.longitude,
    this.loungeId,
    this.status,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [latitude, longitude, loungeId, status, limit, offset];
}

class GetTournamentsUseCase implements UseCase<List<TournamentEntity>, GetTournamentsParams> {
  final TournamentRepository repository;

  GetTournamentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TournamentEntity>>> call(GetTournamentsParams params) {
    return repository.getTournaments(
      latitude: params.latitude,
      longitude: params.longitude,
      loungeId: params.loungeId,
      status: params.status,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class CreateTournamentUseCase implements UseCase<TournamentEntity, TournamentEntity> {
  final TournamentRepository repository;

  CreateTournamentUseCase(this.repository);

  @override
  Future<Either<Failure, TournamentEntity>> call(TournamentEntity tournament) {
    return repository.createTournament(tournament);
  }
}

class UpdateTournamentUseCase implements UseCase<TournamentEntity, TournamentEntity> {
  final TournamentRepository repository;

  UpdateTournamentUseCase(this.repository);

  @override
  Future<Either<Failure, TournamentEntity>> call(TournamentEntity tournament) {
    return repository.updateTournament(tournament);
  }
}

class SaveTournamentPrizesParams extends Equatable {
  final String tournamentId;
  final List<TournamentPrizeEntity> prizes;

  const SaveTournamentPrizesParams({required this.tournamentId, required this.prizes});

  @override
  List<Object?> get props => [tournamentId, prizes];
}

class SaveTournamentPrizesUseCase implements UseCase<void, SaveTournamentPrizesParams> {
  final TournamentRepository repository;

  SaveTournamentPrizesUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveTournamentPrizesParams params) {
    return repository.saveTournamentPrizes(params.tournamentId, params.prizes);
  }
}

class PublishTournamentUseCase implements UseCase<void, String> {
  final TournamentRepository repository;

  PublishTournamentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String tournamentId) {
    return repository.publishTournament(tournamentId);
  }
}

class CancelTournamentParams extends Equatable {
  final String tournamentId;
  final String reason;

  const CancelTournamentParams({required this.tournamentId, required this.reason});

  @override
  List<Object?> get props => [tournamentId, reason];
}

class CancelTournamentUseCase implements UseCase<void, CancelTournamentParams> {
  final TournamentRepository repository;

  CancelTournamentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CancelTournamentParams params) {
    return repository.cancelTournament(params.tournamentId, params.reason);
  }
}

class DeleteTournamentUseCase implements UseCase<void, String> {
  final TournamentRepository repository;

  DeleteTournamentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String tournamentId) {
    return repository.deleteTournament(tournamentId);
  }
}

class CompleteTournamentUseCase implements UseCase<void, String> {
  final TournamentRepository repository;

  CompleteTournamentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String tournamentId) {
    return repository.completeTournament(tournamentId);
  }
}

class AwardPrizesUseCase implements UseCase<Map<String, dynamic>, String> {
  final TournamentRepository repository;

  AwardPrizesUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(String tournamentId) {
    return repository.awardPrizes(tournamentId);
  }
}

class DeleteDraftTournamentUseCase implements UseCase<void, String> {
  final TournamentRepository repository;

  DeleteDraftTournamentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String tournamentId) {
    return repository.deleteDraftTournament(tournamentId);
  }
}

class GetTournamentAuditLogsParams extends Equatable {
  final String tournamentId;
  final int page;
  final int pageSize;

  const GetTournamentAuditLogsParams({
    required this.tournamentId,
    this.page = 1,
    this.pageSize = 50,
  });

  @override
  List<Object?> get props => [tournamentId, page, pageSize];
}

class GetTournamentAuditLogsUseCase
    implements UseCase<PaginatedResult<TournamentAuditLogEntity>, GetTournamentAuditLogsParams> {
  final TournamentRepository repository;

  GetTournamentAuditLogsUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<TournamentAuditLogEntity>>> call(
      GetTournamentAuditLogsParams params) {
    return repository.getTournamentAuditLogsPage(
      tournamentId: params.tournamentId,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}

class WatchDisputedMatchesUseCase {
  final TournamentRepository repository;

  WatchDisputedMatchesUseCase(this.repository);

  Stream<List<TournamentMatchEntity>> call(String tournamentId) {
    return repository.watchDisputedMatches(tournamentId);
  }
}

