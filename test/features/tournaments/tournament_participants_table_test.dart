import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_participant_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_entity.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/widgets/tournament_participants_table.dart';

void main() {
  for (final status in [
    null,
    TournamentStatus.registrationOpen,
    TournamentStatus.checkInClosed,
    TournamentStatus.drawCompleted,
    TournamentStatus.inProgress,
    TournamentStatus.completed,
    TournamentStatus.cancelled,
  ]) {
    testWidgets('withdrawal matches server phase $status', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(1920, 1080),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: TournamentParticipantsTable(
                tournamentStatus: status,
                participants: [
                  TournamentParticipantEntity(
                    id: 'p1',
                    tournamentId: 't1',
                    userId: 'u1',
                    userName: 'Alpha',
                    paymentStatus: ParticipantPaymentStatus.approved,
                    participantStatus: ParticipantStatus.checkedIn,
                    registeredAt: DateTime(2026, 10, 16),
                  ),
                ],
                onApprovePayment: (_) {},
                onRejectPayment: (_, _) {},
                onRecordCash: (_) {},
                onCheckIn: (_) {},
                onWithdraw: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final permitted =
          status == TournamentStatus.registrationOpen ||
          status == TournamentStatus.checkInClosed;
      expect(
        find.text(AppStrings.withdraw),
        permitted ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
  TournamentParticipantEntity participant() => TournamentParticipantEntity(
    id: 'participant-1',
    tournamentId: 'tournament-1',
    userId: 'user-1',
    userName: 'Player One',
    userPhone: '01000000000',
    paymentStatus: ParticipantPaymentStatus.pending,
    registeredAt: DateTime(2026, 9, 29),
  );

  testWidgets('participants remain readable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1920, 1080),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: TournamentParticipantsTable(
                participants: [participant()],
                onApprovePayment: (_) {},
                onRejectPayment: (_, reason) {},
                onRecordCash: (_) {},
                onCheckIn: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Player One'), findsOneWidget);
    expect(find.text('01000000000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('participants use the desktop data table and scrollbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1920, 1080),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: TournamentParticipantsTable(
                participants: [participant()],
                onApprovePayment: (_) {},
                onRejectPayment: (_, reason) {},
                onRecordCash: (_) {},
                onCheckIn: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.byType(Scrollbar), findsOneWidget);
    expect(find.text('Player One'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
