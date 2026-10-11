import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/online_booking_status.dart';

void main() {
  testWidgets('open lounge with offline cashier shows paused bookings, not ready', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: OnlineBookingStatus(
      loungeId: 'lounge-id',
      loader: (_) async => {'status': 'technical_issue', 'can_book_online': false},
    ))));
    await tester.pumpAndSettle();
    expect(find.text('online_booking_status_paused'), findsOneWidget);
    expect(find.text('online_booking_status_ready'), findsNothing);
    expect(find.text('offline_workspace.resume'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('unverified status does not claim online booking is available', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: OnlineBookingStatus(
      loungeId: 'lounge-id', loader: (_) async => throw Exception('connection failed'),
    ))));
    await tester.pumpAndSettle();
    expect(find.text('online_booking_status_unknown'), findsOneWidget);
    expect(find.text('online_booking_status_ready'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
