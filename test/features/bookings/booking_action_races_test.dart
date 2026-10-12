import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/repositories/booking_repository.dart';
import 'package:play_spot_dashboard/features/bookings/domain/usecases/confirm_cash_payment.dart';
import 'package:play_spot_dashboard/features/bookings/domain/usecases/create_booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/usecases/start_booking_session.dart';
import 'package:play_spot_dashboard/features/bookings/domain/usecases/update_booking_status.dart';
import 'package:play_spot_dashboard/features/bookings/domain/usecases/watch_bookings.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';

class _Repository extends Mock implements BookingRepository {}

class _Audio extends Mock implements AudioService {}

void main() {
  late _Repository repository;
  late BookingCubit cubit;
  late StreamController<List<Booking>> events;
  Booking booking(String id, {PaymentStatus payment = PaymentStatus.unpaid}) =>
      Booking(
        id: id,
        userId: 'customer',
        loungeId: 'branch',
        roomId: 'room',
        date: DateTime(2026, 10, 12),
        startTime: '18:00',
        endTime: '19:00',
        status: BookingStatus.upcoming,
        totalPrice: 100,
        paymentStatus: payment,
      );
  setUp(() {
    repository = _Repository();
    events = StreamController<List<Booking>>.broadcast();
    when(
      () => repository.autoCancelExpiredBookings(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => repository.watchBookings(loungeId: any(named: 'loungeId')),
    ).thenAnswer((_) => events.stream);
    cubit = BookingCubit(
      watchBookings: WatchBookings(repository),
      updateBookingStatus: UpdateBookingStatus(repository),
      confirmCashPaymentUseCase: ConfirmCashPayment(repository),
      createBookingUseCase: CreateBooking(repository),
      startBookingSessionUseCase: StartBookingSession(repository),
      repository: repository,
      audioService: _Audio(),
    );
    cubit.startWatchingBookings(loungeId: 'branch');
  });
  tearDown(() async {
    await cubit.close();
    await events.close();
  });
  Future<void> seed(List<Booking> values) async {
    events.add(values);
    await Future<void>.delayed(Duration.zero);
  }

  test(
    'failed approval preserves newer authoritative payment updates',
    () async {
      await seed([booking('one')]);
      final pending = Completer<Either<Failure, void>>();
      when(
        () => repository.approveBooking('one'),
      ).thenAnswer((_) => pending.future);
      final action = cubit.approveBooking('one');
      await seed([booking('one', payment: PaymentStatus.paid)]);
      pending.complete(const Left(ServerFailure('permissionDenied')));
      expect(await action, isFalse);
      expect(cubit.state.bookings.single.paymentStatus, PaymentStatus.paid);
    },
  );

  test('late failed action cannot restore previous branch bookings', () async {
    await seed([booking('one')]);
    final pending = Completer<Either<Failure, void>>();
    when(
      () => repository.approveBooking('one'),
    ).thenAnswer((_) => pending.future);
    final action = cubit.approveBooking('one');
    final other = StreamController<List<Booking>>.broadcast();
    when(
      () => repository.watchBookings(loungeId: 'other'),
    ).thenAnswer((_) => other.stream);
    cubit.startWatchingBookings(loungeId: 'other');
    other.add([booking('two').copyWith(loungeId: 'other')]);
    await Future<void>.delayed(Duration.zero);
    pending.complete(const Left(ServerFailure('permissionDenied')));
    expect(await action, isFalse);
    expect(cubit.state.bookings.single.id, 'two');
    await cubit.close();
    await other.close();
  });

  test('same booking action is dispatched only once while pending', () async {
    await seed([booking('one')]);
    final pending = Completer<Either<Failure, void>>();
    when(
      () => repository.approveBooking('one'),
    ).thenAnswer((_) => pending.future);
    final first = cubit.approveBooking('one');
    final second = cubit.approveBooking('one');
    pending.complete(const Right(null));
    await Future.wait([first, second]);
    verify(() => repository.approveBooking('one')).called(1);
  });

  test('voucher failure after disposal cannot emit', () async {
    final pending = Completer<Either<Failure, Map<String, dynamic>>>();
    when(
      () => repository.validateVoucherByCode('CODE'),
    ).thenAnswer((_) => pending.future);
    final action = cubit.validateVoucherCode('CODE');
    await cubit.close();
    pending.complete(const Left(ServerFailure('invalidVoucher')));
    expect(await action, isNull);
  });
  test('late pagination cannot overwrite latest requested branch', () async {
    final first = Completer<Either<Failure, PaginatedResult<Booking>>>();
    final second = Completer<Either<Failure, PaginatedResult<Booking>>>();
    when(
      () => repository.getLoungeBookingsPage(
        loungeId: 'first',
        page: 1,
        pageSize: 20,
      ),
    ).thenAnswer((_) => first.future);
    when(
      () => repository.getLoungeBookingsPage(
        loungeId: 'second',
        page: 1,
        pageSize: 20,
      ),
    ).thenAnswer((_) => second.future);
    final older = cubit.fetchLoungeBookingsPage(loungeId: 'first');
    final newer = cubit.fetchLoungeBookingsPage(loungeId: 'second');
    second.complete(
      Right(
        PaginatedResult(
          items: [booking('second')],
          totalCount: 1,
          page: 1,
          pageSize: 20,
        ),
      ),
    );
    await newer;
    first.complete(
      Right(
        PaginatedResult(
          items: [booking('first')],
          totalCount: 1,
          page: 1,
          pageSize: 20,
        ),
      ),
    );
    await older;
    expect(cubit.state.bookings.single.id, 'second');
  });
  test(
    'pending cash collection never claims paid before server confirmation',
    () async {
      await seed([booking('one')]);
      final pending = Completer<Either<Failure, void>>();
      when(
        () => repository.confirmCashPayment(
          'one',
          shiftId: null,
          discountAmount: null,
          discountPercentage: null,
          discountReason: null,
        ),
      ).thenAnswer((_) => pending.future);
      final action = cubit.confirmCashPayment('one');
      expect(cubit.state.bookings.single.paymentStatus, PaymentStatus.unpaid);
      pending.complete(const Right(null));
      await action;
      await seed([booking('one', payment: PaymentStatus.paid)]);
      expect(cubit.state.bookings.single.paymentStatus, PaymentStatus.paid);
    },
  );
}
