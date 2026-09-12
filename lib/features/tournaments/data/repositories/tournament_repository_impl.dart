import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/tournament_audit_log_entity.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_match_entity.dart';
import '../../domain/entities/tournament_participant_entity.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../datasources/tournament_remote_data_source.dart';
import '../models/tournament_model.dart';

class TournamentRepositoryImpl implements TournamentRepository {
  final TournamentRemoteDataSource remoteDataSource;

  TournamentRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<TournamentEntity>>> getTournaments({
    String? loungeId,
    String? status,
  }) async {
    try {
      final result = await remoteDataSource.getTournaments(
        loungeId: loungeId,
        status: status,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentEntity>> createTournament(TournamentEntity tournament) async {
    try {
      final model = TournamentModel.fromEntity(tournament);
      final result = await remoteDataSource.createTournament(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentEntity>> updateTournament(TournamentEntity tournament) async {
    try {
      final model = TournamentModel.fromEntity(tournament);
      final result = await remoteDataSource.updateTournament(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> publishTournament(String tournamentId) async {
    try {
      await remoteDataSource.publishTournament(tournamentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelTournament(String tournamentId, String reason) async {
    try {
      await remoteDataSource.cancelTournament(tournamentId, reason);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDraftTournament(String tournamentId) async {
    try {
      await remoteDataSource.deleteDraftTournament(tournamentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TournamentParticipantEntity>>> getParticipants(String tournamentId) async {
    try {
      final result = await remoteDataSource.getParticipants(tournamentId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approvePayment(String participantId) async {
    try {
      await remoteDataSource.approvePayment(participantId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectPayment(String participantId, String reason) async {
    try {
      await remoteDataSource.rejectPayment(participantId, reason);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordCashPayment(String participantId) async {
    try {
      await remoteDataSource.recordCashPayment(participantId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> checkInParticipant(String participantId) async {
    try {
      await remoteDataSource.checkInParticipant(participantId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TournamentMatchEntity>>> drawBracket(String tournamentId) async {
    try {
      final result = await remoteDataSource.drawBracket(tournamentId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TournamentMatchEntity>>> getMatches(String tournamentId) async {
    try {
      final result = await remoteDataSource.getMatches(tournamentId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> startMatch(String matchId, {String? roomId}) async {
    try {
      await remoteDataSource.startMatch(matchId, roomId: roomId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resolveDispute(
    String matchId, {
    required String winnerId,
    required int p1Score,
    required int p2Score,
    required String resolutionNotes,
  }) async {
    try {
      await remoteDataSource.resolveDispute(
        matchId,
        winnerId: winnerId,
        p1Score: p1Score,
        p2Score: p2Score,
        resolutionNotes: resolutionNotes,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> completeTournament(String tournamentId) async {
    try {
      await remoteDataSource.completeTournament(tournamentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> awardPrizes(String tournamentId) async {
    try {
      final result = await remoteDataSource.awardPrizes(tournamentId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TournamentAuditLogEntity>>> getAuditLogs(String tournamentId) async {
    try {
      final result = await remoteDataSource.getAuditLogs(tournamentId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<TournamentAuditLogEntity>>> getTournamentAuditLogsPage({
    required String tournamentId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final result = await remoteDataSource.getTournamentAuditLogsPage(
        tournamentId: tournamentId,
        page: page,
        pageSize: pageSize,
      );
      return Right(PaginatedResult<TournamentAuditLogEntity>(
        items: result.items,
        totalCount: result.totalCount,
        page: result.page,
        pageSize: result.pageSize,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<TournamentMatchEntity>> watchDisputedMatches(String tournamentId) {
    return remoteDataSource.watchDisputedMatches(tournamentId);
  }
}
