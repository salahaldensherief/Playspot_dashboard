import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_match_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/widgets/tournament_bracket_view.dart';

void main() {
  testWidgets(
    'championship and bronze have separate columns and start callbacks',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? started;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(1920, 1080),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: TournamentBracketView(
                matches: const [
                  TournamentMatchEntity(
                    id: 'final',
                    tournamentId: 't',
                    round: 3,
                    matchNumber: 1,
                    status: MatchStatus.completed,
                  ),
                  TournamentMatchEntity(
                    id: 'bronze',
                    tournamentId: 't',
                    round: 3,
                    matchNumber: 2,
                    matchType: 'third_place',
                    player1Id: 'p1',
                    player2Id: 'p2',
                    status: MatchStatus.scheduled,
                  ),
                ],
                onDrawBracket: () {},
                onRefresh: () {},
                onStartMatch: (m) => started = m.id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.thirdPlace), findsOneWidget);
      expect(find.text(AppStrings.finalRound), findsOneWidget);
      await tester.tap(find.text(AppStrings.startSession));
      expect(started, 'bronze');
      expect(tester.takeException(), isNull);
    },
  );
}
