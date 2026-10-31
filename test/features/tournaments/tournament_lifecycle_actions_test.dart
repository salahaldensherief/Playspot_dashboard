import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/widgets/tournament_selector_bar.dart';

void main() {
  for (final status in [
    TournamentStatus.drawCompleted,
    TournamentStatus.inProgress,
    TournamentStatus.completed,
    TournamentStatus.cancelled,
  ]) {
    testWidgets(
      '$status offers only the appropriate completion and prize action',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final t = TournamentEntity(
          id: 't1',
          title: 'Local Cup',
          gameTitle: 'EA FC',
          treeSize: 8,
          status: status,
          entryFee: 100,
          prizePool: 0,
          startDate: DateTime(2026, 10, 16),
          endDate: DateTime(2026, 10, 16),
          registrationDeadline: DateTime(2026, 10, 15),
          minPlayers: 2,
          maxPlayers: 8,
        );
        var completed = 0, awarded = 0;
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(1920, 1080),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: TournamentSelectorBar(
                  tournaments: [t],
                  selected: t,
                  onSelect: (_) {},
                  onManagePrizes: () {},
                  onPublish: () {},
                  onDeleteDraft: () {},
                  onCancel: () {},
                  onComplete: () => completed++,
                  onAwardPrizes: () => awarded++,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(AppStrings.managePrizes),
          status == TournamentStatus.drawCompleted
              ? findsOneWidget
              : findsNothing,
        );
        if (status == TournamentStatus.completed) {
          expect(find.text(AppStrings.cancelTournament), findsNothing);
          await tester.tap(find.text(AppStrings.awardTournamentPrizes));
          expect(awarded, 1);
          expect(completed, 0);
        } else if (status == TournamentStatus.cancelled) {
          expect(find.text(AppStrings.completeTournament), findsNothing);
          expect(find.text(AppStrings.awardTournamentPrizes), findsNothing);
          expect(find.text(AppStrings.cancelTournament), findsNothing);
        } else {
          await tester.tap(find.text(AppStrings.completeTournament));
          expect(completed, 1);
          expect(awarded, 0);
          expect(find.text(AppStrings.awardTournamentPrizes), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
