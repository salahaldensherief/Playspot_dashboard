import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/widgets/tournament_card.dart';

void main() {
  for (final status in TournamentStatus.values) {
    testWidgets('card actions follow backend phase rules: $status', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final tournament = TournamentEntity(
        id: 'local',
        title: 'QA',
        treeSize: 8,
        status: status,
        entryFee: 0,
        prizePool: 0,
        startDate: DateTime(2026),
        endDate: DateTime(2026),
        registrationDeadline: DateTime(2026),
        minPlayers: 2,
        maxPlayers: 8,
      );
      var selected = 0;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(1920, 1080),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: TournamentCard(
                tournament: tournament,
                isSelected: false,
                onSelect: () => selected++,
                onEdit: () {},
                onDelete: () {},
                onManagePrizes: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final editable = [
        TournamentStatus.draft,
        TournamentStatus.published,
        TournamentStatus.registrationOpen,
      ].contains(status);
      final locked = [
        TournamentStatus.inProgress,
        TournamentStatus.completed,
        TournamentStatus.cancelled,
      ].contains(status);
      expect(
        find.text(AppStrings.edit),
        editable ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(AppStrings.managePrizes),
        locked ? findsNothing : findsOneWidget,
      );
      expect(find.text(AppStrings.deleteTournament), findsNothing);
      expect(
        find.text(AppStrings.deleteDraft),
        status == TournamentStatus.draft ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(AppStrings.cancelTournament),
        ![
              TournamentStatus.draft,
              TournamentStatus.completed,
              TournamentStatus.cancelled,
            ].contains(status)
            ? findsOneWidget
            : findsNothing,
      );
      await tester.tap(find.text(AppStrings.viewAll));
      expect(selected, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
