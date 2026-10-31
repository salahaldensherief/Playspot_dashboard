import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_match_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/widgets/tournament_bracket_view.dart';

void main() {
  testWidgets('refreshing an existing bracket never requests another draw', (
    tester,
  ) async {
    var draws = 0;
    var reads = 0;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1920, 1080),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: TournamentBracketView(
              matches: const [
                TournamentMatchEntity(
                  id: 'm-1',
                  tournamentId: 't-1',
                  round: 1,
                  matchNumber: 1,
                  status: MatchStatus.completed,
                  player1Id: 'p1',
                  player2Id: 'p2',
                ),
              ],
              onDrawBracket: () => draws++,
              onRefresh: () => reads++,
              onStartMatch: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.refresh));
    expect(
      draws,
      0,
      reason: 'Refresh is a read; the draw RPC mutates the tournament',
    );
    expect(reads, 1);
    expect(tester.takeException(), isNull);
  });
}
