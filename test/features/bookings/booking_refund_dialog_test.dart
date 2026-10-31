import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/repositories/booking_refund_repository.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_refund_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_refund_dialog.dart';
import '../../support/local_translations_loader.dart';
import 'booking_refund_contract_test.dart' show testSummary;
import 'package:play_spot_dashboard/features/audit/presentation/widgets/audit_labels.dart';

class _Login extends Mock implements LoginCubit {}

class _Shifts extends Mock implements ShiftCubit {}

class _Repository extends Mock implements BookingRefundRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final language in ['en', 'ar']) {
    testWidgets(
      'real refund dialog $language narrow enlarged text and missing-shift guard',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final login = _Login(), shifts = _Shifts(), repository = _Repository();
        when(() => login.state).thenReturn(
          const LoginState(
            status: LoginStatus.authenticated,
            user: UserEntity(
              id: 'owner',
              email: 'synthetic@example.invalid',
              name: 'Synthetic',
              role: UserRole.owner,
              loungeId: 'lounge',
            ),
          ),
        );
        when(() => login.stream).thenAnswer((_) => const Stream.empty());
        when(() => shifts.state).thenReturn(ShiftState.initial());
        when(() => shifts.stream).thenAnswer((_) => const Stream.empty());
        when(() => repository.writesEnabled).thenReturn(true);
        when(
          () => repository.summary('booking', 'lounge'),
        ).thenAnswer((_) async => testSummary);
        final cubit = BookingRefundCubit(repository, 'booking', 'lounge');
        addTearDown(cubit.close);
        await cubit.load();
        final booking = Booking(
          id: 'booking',
          userId: 'customer',
          loungeId: 'lounge',
          roomId: 'room',
          date: DateTime(2030),
          startTime: '12:00',
          endTime: '13:00',
          status: BookingStatus.completed,
          paymentStatus: PaymentStatus.paid,
          totalPrice: 100,
        );
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('ar')],
            startLocale: Locale(language),
            saveLocale: false,
            path: 'assets/translations',
            assetLoader: const LocalTranslationsLoader(),
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.6)),
                  child: child!,
                ),
                home: MultiBlocProvider(
                  providers: [
                    BlocProvider<LoginCubit>.value(value: login),
                    BlocProvider<ShiftCubit>.value(value: shifts),
                    BlocProvider.value(value: cubit),
                  ],
                  child: Scaffold(body: BookingRefundDialog(booking: booking)),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final dialog = tester.element(find.byType(BookingRefundDialog));
        expect(
          Directionality.of(dialog),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        final returnButton = find.widgetWithText(
          FilledButton,
          AppStrings.refundRecordReturn,
        );
        await tester.ensureVisible(returnButton);
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(returnButton).onPressed, isNull);
        expect(find.text(AppStrings.refundOwnShift), findsOneWidget);
        expect(find.text(AppStrings.refundSeparation), findsOneWidget);
        expect(
          auditActionLabel('payment_refunded', payload: {'stage': 'initiated'}),
          AppStrings.refundRequestConfirmed,
        );
        expect(
          auditActionLabel('payment_refunded', payload: {'stage': 'completed'}),
          AppStrings.refundReturnConfirmed,
        );
        expect(auditActionLabel('payment_refunded'), AppStrings.refundManage);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
