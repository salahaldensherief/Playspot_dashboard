import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import '../models/tournament_audit_log_model.dart';
import '../models/tournament_match_model.dart';
import '../models/tournament_model.dart';
import '../models/tournament_participant_model.dart';
import '../models/tournament_prize_model.dart';

abstract class TournamentRemoteDataSource {
  Future<List<TournamentModel>> getTournaments({
    double? latitude,
    double? longitude,
    String? loungeId,
    String? status,
    int limit = 50,
    int offset = 0,
  });
  Future<TournamentModel> createTournament(TournamentModel tournament);
  Future<TournamentModel> updateTournament(TournamentModel tournament);
  Future<void> saveTournamentPrizes(String tournamentId, List<TournamentPrizeModel> prizes);
  Future<void> publishTournament(String tournamentId);
  Future<void> cancelTournament(String tournamentId, String reason);
  Future<void> deleteDraftTournament(String tournamentId);
  Future<void> deleteTournament(String tournamentId);

  Future<List<TournamentParticipantModel>> getParticipants(String tournamentId);
  Future<void> approvePayment(String participantId);
  Future<void> rejectPayment(String participantId, String reason);
  Future<void> recordCashPayment(String participantId);
  Future<void> promoteWaitlist(String tournamentId);
  Future<void> checkInParticipant(String participantId);
  Future<void> withdrawParticipant(String participantId);

  Future<List<TournamentMatchModel>> drawBracket(String tournamentId);
  Future<List<TournamentMatchModel>> getMatches(String tournamentId);
  Future<void> startMatch(String matchId, {String? roomId});
  Future<void> resolveDispute(
    String matchId, {
    required String winnerId,
    required int p1Score,
    required int p2Score,
    required String resolutionNotes,
  });

  Future<void> completeTournament(String tournamentId);
  Future<Map<String, dynamic>> awardPrizes(String tournamentId);
  Future<List<TournamentAuditLogModel>> getAuditLogs(String tournamentId);
  Future<PaginatedResult<TournamentAuditLogModel>> getTournamentAuditLogsPage({
    required String tournamentId,
    int page = 1,
    int pageSize = 50,
  });

  Stream<List<TournamentMatchModel>> watchDisputedMatches(String tournamentId);
}
