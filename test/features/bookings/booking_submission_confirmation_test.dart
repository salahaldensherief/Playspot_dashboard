import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/repositories/booking_repository.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_dialog.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';
import '../../support/local_translations_loader.dart';

class _Bookings extends Mock implements BookingCubit {}

class _Repository extends Mock implements BookingRepository {}

class _Rooms extends Mock implements RoomCubit {}

const room = RoomEntity(
  id: 'room',
  loungeId: 'lounge',
  nameEn: 'Room',
  nameAr: 'غرفة',
  hourlyRateSingle: 60,
  hourlyRateMulti: 80,
  isAvailable: true,
  images: [],
  featuresAr: [],
  featuresEn: [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(
      Booking(
        id: 'fixture',
        userId: '',
        loungeId: 'lounge',
        roomId: 'room',
        date: DateTime(2026),
        startTime: '00:00',
        endTime: '01:00',
        status: BookingStatus.upcoming,
        totalPrice: 60,
      ),
    );
  });
  late _Bookings bookings;
  late _Repository repository;
  late _Rooms rooms;
  setUp(() {
    bookings = _Bookings();
    repository = _Repository();
    rooms = _Rooms();
    when(
      () => bookings.state,
    ).thenReturn(const BookingState(selectedDurationMinutes: 60));
    when(() => bookings.stream).thenAnswer((_) => const Stream.empty());
    when(() => bookings.repository).thenReturn(repository);
    when(() => bookings.updateSelectedDuration(any())).thenReturn(null);
    when(() => rooms.state).thenReturn(const RoomState(rooms: [room]));
    when(() => rooms.stream).thenAnswer((_) => const Stream.empty());
  });
  Future<void> mount(WidgetTester tester, {bool quickMode = false}) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        startLocale: const Locale('en'),
        saveLocale: false,
        path: 'assets/translations',
        assetLoader: const LocalTranslationsLoader(),
        child: ScreenUtilInit(
          designSize: const Size(1440, 900),
          builder: (context, _) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              body: MultiBlocProvider(
                providers: [
                  BlocProvider<BookingCubit>.value(value: bookings),
                  BlocProvider<RoomCubit>.value(value: rooms),
                ],
                child: AddBookingDialog(
                  loungeId: 'lounge',
                  initialRoom: room,
                  quickMode: quickMode,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2500),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AppButton &&
            widget.text ==
                (quickMode ? AppStrings.walkInBooking : AppStrings.newBooking),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  void noCreate() => verifyNever(() => bookings.createBooking(any()));
  for (final scenario in ['cancel', 'quick-cancel', 'denied', 'disposed']) {
    testWidgets(
      'cash submission $scenario never collects or creates implicitly',
      (tester) async {
        final delayed = Completer<Either<Failure, Map<String, dynamic>>>();
        when(
          () => repository.verifyAndHoldSlot(
            roomId: any(named: 'roomId'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            holdMinutes: 10,
          ),
        ).thenAnswer((_) => delayed.future);
        await mount(tester, quickMode: scenario == 'quick-cancel');
        expect(
          find.text('booking_cash_confirmation_title'.tr()),
          findsOneWidget,
        );
        verifyNever(
          () => repository.verifyAndHoldSlot(
            roomId: any(named: 'roomId'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            holdMinutes: 10,
          ),
        );
        if (scenario == 'cancel' || scenario == 'quick-cancel') {
          await tester.tap(find.text(AppStrings.cancel).last);
          await tester.pumpAndSettle();
          noCreate();
          expect(
            find.text('booking_cash_confirmation_title'.tr()),
            findsNothing,
          );
          return;
        }
        await tester.tap(find.text('booking_cash_confirmation_action'.tr()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        verify(
          () => repository.verifyAndHoldSlot(
            roomId: any(named: 'roomId'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            holdMinutes: 10,
          ),
        ).called(1);
        // Repeat taps while awaiting the hold must not start another operation.
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is AppButton && widget.text == AppStrings.newBooking,
          ),
          warnIfMissed: false,
        );
        await tester.pump();
        verifyNever(
          () => repository.verifyAndHoldSlot(
            roomId: any(named: 'roomId'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            holdMinutes: 10,
          ),
        );
        if (scenario == 'disposed')
          await tester.pumpWidget(const SizedBox.shrink());
        delayed.complete(const Left(ServerFailure('Slot unavailable')));
        await tester.pump();
        noCreate();
        if (scenario == 'denied')
          expect(find.text('Slot unavailable'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
