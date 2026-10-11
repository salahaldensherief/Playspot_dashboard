import 'dart:async';

import 'package:play_spot_dashboard/core/utils/paginated_result.dart';

import '../domain/entities/tournament_audit_log_entity.dart';
import '../domain/entities/tournament_match_entity.dart';
import '../domain/usecases/tournament_usecases.dart';

class TournamentAuditManager {
  final GetTournamentAuditLogsUseCase getTournamentAuditLogsUseCase;
  final WatchDisputedMatchesUseCase watchDisputedMatchesUseCase;
  StreamSubscription<List<TournamentMatchEntity>>? _disputesSubscription;
  int _watchGeneration = 0;
  bool _disposed = false;

  TournamentAuditManager({
    required this.getTournamentAuditLogsUseCase,
    required this.watchDisputedMatchesUseCase,
  });

  Future<PaginatedResult<TournamentAuditLogEntity>?> loadAuditLogs(
    String tournamentId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    if (_disposed) return null;
    final result = await getTournamentAuditLogsUseCase(
      GetTournamentAuditLogsParams(
        tournamentId: tournamentId,
        page: page,
        pageSize: pageSize,
      ),
    );
    if (_disposed) return null;
    return result.fold((_) => null, (paginated) => paginated);
  }

  void startWatchingDisputes(
    String tournamentId,
    void Function(List<TournamentMatchEntity>) onDisputesUpdated,
  ) {
    if (_disposed) return;
    final generation = ++_watchGeneration;
    _disputesSubscription?.cancel();
    _disputesSubscription = watchDisputedMatchesUseCase(tournamentId)
        .listen((matches) {
          if (!_disposed && generation == _watchGeneration) {
            onDisputesUpdated(matches);
          }
        });
  }

  void dispose() {
    _disposed = true;
    _watchGeneration++;
    _disputesSubscription?.cancel();
    _disputesSubscription = null;
  }
}
