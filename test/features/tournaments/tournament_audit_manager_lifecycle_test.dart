import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_match_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/usecases/tournament_usecases.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_audit_manager.dart';

class _GetLogs extends Mock implements GetTournamentAuditLogsUseCase {}
class _WatchMatches extends Mock implements WatchDisputedMatchesUseCase {}

void main() {
  test('switching tournaments cancels the old watcher and dispose is terminal', () async {
    final watch = _WatchMatches();
    final first = StreamController<List<TournamentMatchEntity>>(sync: true);
    final second = StreamController<List<TournamentMatchEntity>>(sync: true);
    when(() => watch('first')).thenAnswer((_) => first.stream);
    when(() => watch('second')).thenAnswer((_) => second.stream);
    final manager = TournamentAuditManager(
      getTournamentAuditLogsUseCase: _GetLogs(),
      watchDisputedMatchesUseCase: watch,
    );
    var updates = 0;
    manager.startWatchingDisputes('first', (_) => updates++);
    first.add([]);
    expect(updates, 1);
    manager.startWatchingDisputes('second', (_) => updates++);
    expect(first.hasListener, isFalse);
    first.add([]);
    second.add([]);
    expect(updates, 2);
    manager.dispose();
    second.add([]);
    manager.startWatchingDisputes('first', (_) => updates++);
    expect(updates, 2);
    verify(() => watch('first')).called(1);
    await first.close();
    await second.close();
  });
}
