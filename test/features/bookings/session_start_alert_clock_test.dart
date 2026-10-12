import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/repositories/booking_repository.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_session_scheduler.dart';

class _Repository extends Mock implements BookingRepository {}

class _Audio extends Mock implements AudioService {}

void main() {
  testWidgets('due start alert arrives without another realtime booking event', (
    tester,
  ) async {
    final repository = _Repository(), audio = _Audio();
    when(
      () => repository.autoCancelExpiredBookings(),
    ).thenAnswer((_) async => const Right(null));
    when(() => audio.playUrgentAlertSound()).thenAnswer((_) async {});
    var now = DateTime(2030, 1, 10, 13, 59, 30);
    final due = DateTime(2030, 1, 10, 14);
    final booking = Booking(
      id: 'due',
      userId: 'customer',
      loungeId: 'branch',
      roomId: 'room',
      date: due,
      startTime:
          '${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}:${due.second.toString().padLeft(2, '0')}',
      endTime: '23:59',
      status: BookingStatus.upcoming,
      paymentStatus: PaymentStatus.paid,
      totalPrice: 100,
    );
    final scheduler = BookingSessionScheduler(
      repository: repository,
      audioService: audio,
      onTransitionStatus: (_, _) {},
      clock: () => now,
    );
    addTearDown(scheduler.dispose);
    scheduler.checkBookingStartTimesAndNotify([booking]);
    verifyNever(() => audio.playUrgentAlertSound());
    scheduler.start();
    now = due;
    await tester.pump(const Duration(seconds: 30));
    verify(() => audio.playUrgentAlertSound()).called(1);
    await tester.pump(const Duration(seconds: 30));
    verifyNever(() => audio.playUrgentAlertSound());
    scheduler.dispose();
  });
}
