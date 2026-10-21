import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/features/support/domain/entities/support_ticket_entity.dart';
import 'package:play_spot_dashboard/features/support/presentation/support_cubit.dart';
import 'package:play_spot_dashboard/features/support/presentation/support_state.dart';
import 'package:play_spot_dashboard/features/support/presentation/support_tickets_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/local_translations_loader.dart';

class _SupportCubit extends Mock implements SupportCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await (FontLoader('Tajawal')
          ..addFont(rootBundle.load('assets/fonts/Tajawal/Tajawal-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Tajawal/Tajawal-Bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> mount(
    WidgetTester tester, {
    required double width,
    required SupportState state,
    required _SupportCubit cubit,
    GlobalKey? capture,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.loadTickets()).thenAnswer((_) async {});
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        startLocale: const Locale('ar'),
        saveLocale: false,
        path: 'assets/translations',
        assetLoader: const LocalTranslationsLoader(),
        child: ScreenUtilInit(
          designSize: width < 600
              ? const Size(390, 844)
              : width < 1200
              ? const Size(768, 1024)
              : const Size(1440, 1024),
          builder: (context, _) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            theme: ThemeData(
              brightness: Brightness.dark,
              fontFamily: 'Tajawal',
            ),
            home: BlocProvider<SupportCubit>.value(
              value: cubit,
              child: RepaintBoundary(
                key: capture,
                child: const SupportTicketsScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final ticket = SupportTicketEntity(
    id: 'ticket-1',
    userName: 'مستخدم تجريبي',
    userPhone: '01000000000',
    issueType: 'حجز',
    message: 'وصف المشكلة في الحجز',
    status: 'new',
    createdAt: DateTime(2026, 10, 20),
  );

  Future<void> saveScreenshot(GlobalKey capture, String name) async {
    final output = Platform.environment['PLAYSPOT_SCREENSHOT_DIR'];
    if (output == null) return;
    final boundary =
        capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(output);
    await dir.create(recursive: true);
    await File(
      '${dir.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  }

  testWidgets('tickets use readable cards on narrow screens', (tester) async {
    final cubit = _SupportCubit();
    final capture = GlobalKey();
    await mount(
      tester,
      width: 360,
      cubit: cubit,
      state: SupportState(status: SupportStatus.success, tickets: [ticket]),
      capture: capture,
    );
    expect(find.byType(Table), findsNothing);
    expect(find.text(ticket.userName), findsOneWidget);
    expect(find.text(ticket.message), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => saveScreenshot(capture, 'support-rtl-360'));
  });

  testWidgets('wide screens retain the detailed ticket table', (tester) async {
    final cubit = _SupportCubit();
    final capture = GlobalKey();
    await mount(
      tester,
      width: 1440,
      cubit: cubit,
      state: SupportState(status: SupportStatus.success, tickets: [ticket]),
      capture: capture,
    );
    expect(find.byType(Table), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => saveScreenshot(capture, 'support-rtl-1440'));
  });

  testWidgets('tablet screens use two ticket columns', (tester) async {
    final cubit = _SupportCubit();
    final capture = GlobalKey();
    await mount(
      tester,
      width: 900,
      cubit: cubit,
      state: SupportState(
        status: SupportStatus.success,
        tickets: [ticket, ticket],
      ),
      capture: capture,
    );
    expect(find.byType(Table), findsNothing);
    expect(find.text(ticket.userName), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => saveScreenshot(capture, 'support-rtl-900'));
  });

  testWidgets('ticket load failure has a retry action', (tester) async {
    final cubit = _SupportCubit();
    await mount(
      tester,
      width: 360,
      cubit: cubit,
      state: const SupportState(
        status: SupportStatus.failure,
        errorMessage: 'تعذر تحميل الطلبات',
      ),
    );
    expect(find.text('تعذر تحميل الطلبات'), findsOneWidget);
    await tester.tap(find.text(AppStrings.retry));
    verify(() => cubit.loadTickets()).called(2);
    expect(tester.takeException(), isNull);
  });
}
