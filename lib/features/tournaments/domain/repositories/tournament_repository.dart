import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import '../../../../core/error/failures.dart';
import '../entities/tournament_audit_log_entity.dart';
import '../entities/tournament_entity.dart';
import '../entities/tournament_match_entity.dart';
import '../entities/tournament_participant_entity.dart';

abstract class TournamentRepository {
  Future<Either<Failure, List<TournamentEntity>>> getTournaments({
    String? loungeId,
    String? status,
  });

  Future<Either<Failure, TournamentEntity>> createTournament(TournamentEntity tournament);

  Future<Either<Failure, TournamentEntity>> updateTournament(TournamentEntity tournament);

  Future<Either<Failure, void>> publishTournament(String tournamentId);

  Future<Either<Failure, void>> cancelTournament(String tournamentId, String reason);

  Future<Either<Failure, void>> deleteDraftTournament(String tournamentId);

  Future<Either<Failure, List<TournamentParticipantEntity>>> getParticipants(String tournamentId);

  Future<Either<Failure, void>> approvePayment(String participantId);

  Future<Either<Failure, void>> rejectPayment(String participantId, String reason);

  Future<Either<Failure, void>> recordCashPayment(String participantId);

  Future<Either<Failure, void>> checkInParticipant(String participantId);

  Future<Either<Failure, List<TournamentMatchEntity>>> drawBracket(String tournamentId);

  Future<Either<Failure, List<TournamentMatchEntity>>> getMatches(String tournamentId);

  Future<Either<Failure, void>> startMatch(String matchId, {String? roomId});

  Future<Either<Failure, void>> resolveDispute(
    String matchId, {
    required String winnerId,
    required int p1Score,
    required int p2Score,
    required String resolutionNotes,
  });

  Future<Either<Failure, void>> completeTournament(String tournamentId);

  Future<Either<Failure, Map<String, dynamic>>> awardPrizes(String tournamentId);

  Future<Either<Failure, List<TournamentAuditLogEntity>>> getAuditLogs(String tournamentId);

  Future<Either<Failure, PaginatedResult<TournamentAuditLogEntity>>> getTournamentAuditLogsPage({
    required String tournamentId,
    int page = 1,
    int pageSize = 50,
  });

  Stream<List<TournamentMatchEntity>> watchDisputedMatches(String tournamentId);
}
