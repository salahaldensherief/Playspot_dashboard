import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_details_action_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_state.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/live_bookings_feed.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/cashier_session_details.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_control_actions.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_operations_summary.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_clock_host.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/start_session_button.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_live_clock.dart';
import '../../support/local_translations_loader.dart';

class _Login extends Mock implements LoginCubit {}

class _Permissions extends Mock implements PermissionsCubit {}

class _Dashboard extends Mock implements DashboardCubit {}

class _Bookings extends Mock implements BookingCubit {}

class _Requests extends Mock implements ClientRequestsCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final booking = Booking(
    id: 'due',
    userId: 'customer',
    loungeId: 'branch',
    roomId: 'room',
    roomName: 'Room',
    date: DateTime(2030, 1, 10),
    startTime: '14:00',
    endTime: '15:00',
    status: BookingStatus.upcoming,
    totalPrice: 100,
    paymentMethod: 'cash',
  );
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    DateTime Function()? clock,
  }) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        startLocale: const Locale('en'),
        saveLocale: false,
        path: 'assets/translations',
        assetLoader: const LocalTranslationsLoader(),
        child: Builder(
          builder: (context) => ScreenUtilInit(
            designSize: const Size(1920, 1080),
            builder: (_, _) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(
                body: SessionClockHost(
                  clock: clock,
                  child: SingleChildScrollView(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'due unstarted booking shows waiting status rather than a running clock',
    (tester) async {
      await mount(
        tester,
        SessionLiveClock(booking: booking),
        clock: () => DateTime(2030, 1, 10, 14, 5),
      );
      expect(find.text('cashier.awaitingStart'.tr()), findsOneWidget);
      expect(find.text('cashier.remaining'.tr()), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'cash collection is separate and absent for pending, refunded and transfer bookings',
    (tester) async {
      for (final sample in [
        booking.copyWith(status: BookingStatus.pending),
        booking.copyWith(paymentStatus: PaymentStatus.refunded),
        booking.copyWith(paymentMethod: 'manual_transfer'),
      ]) {
        await mount(tester, SessionControlActions(booking: sample));
        expect(find.text('cashier.collect'.tr()), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      }
      await mount(tester, SessionControlActions(booking: booking));
      expect(find.text('cashier.controlsSection'.tr()), findsOneWidget);
      expect(find.text('cashier.collectionSection'.tr()), findsOneWidget);
      expect(find.text('cashier.postpaidHint'.tr()), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'drawer details omit duplicate booking actions while the workspace retains them',
    (tester) async {
      await mount(
        tester,
        CashierSessionDetails(
          summary: SessionOperationsSummary(booking, null),
          requests: const [],
          showActions: false,
        ),
      );
      expect(find.byType(StartSessionButton), findsNothing);
      expect(find.text(AppStrings.confirmCash), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'approved unpaid booking collect action reaches the payment flow',
    (tester) async {
      var calls = 0;
      await mount(
        tester,
        CashierSessionDetails(
          summary: SessionOperationsSummary(booking, null),
          requests: const [],
          onManage: () => calls++,
        ),
      );
      final collect = find.text(AppStrings.confirmCash);
      expect(collect, findsOneWidget);
      await tester.ensureVisible(collect);
      await tester.tap(collect);
      await tester.pump();
      expect(calls, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('station controls expose cash start before collection', (
    tester,
  ) async {
    await mount(
      tester,
      SessionControlActions(booking: booking),
      clock: () => DateTime(2030, 1, 10, 14),
    );
    expect(find.byType(StartSessionButton), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'start button follows the session clock without database events',
    (tester) async {
      var now = DateTime(2030, 1, 10, 13, 59, 59);
      await mount(
        tester,
        StartSessionButton(
          bookingId: booking.id,
          bookingDate: booking.date,
          startTime: booking.startTime,
        ),
        clock: () => now,
      );
      expect(find.text(AppStrings.startSession), findsNothing);
      now = DateTime(2030, 1, 10, 14);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(AppStrings.startSession), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'fresh paid booking overrides an older unpaid analytics projection',
    (tester) async {
      final dashboard = _Dashboard(),
          bookings = _Bookings(),
          requests = _Requests();
      when(
        () => dashboard.state,
      ).thenReturn(DashboardState(activeSessionsList: [booking]));
      when(
        () => dashboard.stream,
      ).thenAnswer((_) => const Stream<DashboardState>.empty());
      when(() => bookings.state).thenReturn(
        BookingState(
          status: BookingStatusState.success,
          bookings: [booking.copyWith(paymentStatus: PaymentStatus.paid)],
        ),
      );
      when(
        () => bookings.stream,
      ).thenAnswer((_) => const Stream<BookingState>.empty());
      when(() => requests.state).thenReturn(const ClientRequestsState());
      when(
        () => requests.stream,
      ).thenAnswer((_) => const Stream<ClientRequestsState>.empty());
      await mount(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider<DashboardCubit>.value(value: dashboard),
            BlocProvider<BookingCubit>.value(value: bookings),
            BlocProvider<ClientRequestsCubit>.value(value: requests),
          ],
          child: const LiveBookingsFeed(),
        ),
        clock: () => DateTime(2030, 1, 10, 14),
      );
      expect(find.byType(StartSessionButton), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'unpaid cash start waits for the server without collecting and retains failures',
    (tester) async {
      final bookings = _Bookings(),
          login = _Login(),
          permissions = _Permissions();
      final pending = Completer<bool>();
      var collections = 0;
      when(
        () => bookings.state,
      ).thenReturn(const BookingState(errorMessage: 'Fixture start failure'));
      when(
        () => bookings.stream,
      ).thenAnswer((_) => const Stream<BookingState>.empty());
      when(
        () => bookings.startBookingSession('due'),
      ).thenAnswer((_) => pending.future);
      when(() => login.state).thenReturn(
        const LoginState(
          user: UserEntity(
            id: 'owner',
            email: 'fixture@local.invalid',
            name: 'Owner',
            role: UserRole.owner,
          ),
        ),
      );
      when(
        () => login.stream,
      ).thenAnswer((_) => const Stream<LoginState>.empty());
      when(
        () => permissions.state,
      ).thenReturn(const PermissionsState(status: PermissionsStatus.success));
      when(
        () => permissions.stream,
      ).thenAnswer((_) => const Stream<PermissionsState>.empty());
      when(
        () => permissions.hasPermission(
          any(),
          userRole: any(named: 'userRole'),
          userId: any(named: 'userId'),
        ),
      ).thenReturn(true);
      await mount(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider<BookingCubit>.value(value: bookings),
                  BlocProvider<LoginCubit>.value(value: login),
                  BlocProvider<PermissionsCubit>.value(value: permissions),
                ],
                child: Dialog(
                  child: SessionClockHost(
                    clock: () => DateTime(2030, 1, 10, 14),
                    child: BookingDetailsActionPanel(
                      booking: booking,
                      isLoading: false,
                      onConfirmCashPayment: () => collections++,
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('Open fixture'),
          ),
        ),
      );
      await tester.tap(find.text('Open fixture'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('start_session_now'.tr()));
      await tester.pump();
      expect(find.byType(BookingDetailsActionPanel), findsOneWidget);
      pending.complete(false);
      await tester.pumpAndSettle();
      expect(find.byType(BookingDetailsActionPanel), findsOneWidget);
      expect(find.text('Fixture start failure'), findsOneWidget);
      expect(collections, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
