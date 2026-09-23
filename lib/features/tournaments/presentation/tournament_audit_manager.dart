import 'dart:async';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import '../domain/entities/tournament_audit_log_entity.dart';
import '../domain/entities/tournament_match_entity.dart';
import '../domain/usecases/tournament_usecases.dart';

class TournamentAuditManager {
  final GetTournamentAuditLogsUseCase getTournamentAuditLogsUseCase;
  final WatchDisputedMatchesUseCase watchDisputedMatchesUseCase;
  StreamSubscription<List<TournamentMatchEntity>>? _disputesSubscription;

  TournamentAuditManager({
    required this.getTournamentAuditLogsUseCase,
    required this.watchDisputedMatchesUseCase,
  });

  Future<PaginatedResult<TournamentAuditLogEntity>?> loadAuditLogs(
    String tournamentId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final result = await getTournamentAuditLogsUseCase(GetTournamentAuditLogsParams(
      tournamentId: tournamentId,
      page: page,
      pageSize: pageSize,
    ));
    return result.fold((_) => null, (paginated) => paginated);
  }

  void startWatchingDisputes(
    String tournamentId,
    void Function(List<TournamentMatchEntity>) onDisputesUpdated,
  ) {
    _disputesSubscription?.cancel();
    _disputesSubscription =
        watchDisputedMatchesUseCase(tournamentId).listen(onDisputesUpdated);
  }

  void dispose() {
    _disputesSubscription?.cancel();
  }
}
