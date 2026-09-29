import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_participant_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/widgets/tournament_participants_table.dart';

void main() {
  testWidgets('participants remain readable on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final participant = TournamentParticipantEntity(
      id: 'participant-1',
      tournamentId: 'tournament-1',
      userId: 'user-1',
      userName: 'Player One',
      userPhone: '01000000000',
      paymentStatus: ParticipantPaymentStatus.pending,
      registeredAt: DateTime(2026, 9, 29),
    );

    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(1920, 1080),
      builder: (context, child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: TournamentParticipantsTable(
              participants: [participant],
              onApprovePayment: (_) {},
              onRejectPayment: (_, reason) {},
              onRecordCash: (_) {},
              onCheckIn: (_) {},
            ),
          ),
        ),
      ),
    ));

    expect(find.text('Player One'), findsOneWidget);
    expect(find.text('01000000000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
