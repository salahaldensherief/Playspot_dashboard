import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/repositories/cashier_workspace_store.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/repositories/offline_cashier_repository.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/local_cashier_command.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/cashier_connection_mode.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/cashier_sync_result.dart';
import 'package:play_spot_dashboard/features/offline_cashier/presentation/offline_workspace_cubit.dart';
import 'package:play_spot_dashboard/features/offline_cashier/presentation/offline_workspace_page.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import '../../support/local_translations_loader.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';

class _Store extends Mock implements CashierWorkspaceStore {}

class _Repo extends Mock implements OfflineCashierRepository {}

class _Login extends Mock implements LoginCubit {}

void main() {
  late _Store store;
  late _Repo repo;
  late OfflineWorkspaceCubit cubit;
  late Map<String, dynamic> projection;
  setUpAll(() async {
    registerFallbackValue(CashierConnectionMode.offline);
    registerFallbackValue(
      LocalCashierCommand(
        id: 'id',
        bookingId: 'b',
        actorId: 'actor',
        loungeId: 'lounge',
        deviceId: 'device',
        permitId: 'p',
        shiftId: 'shift',
        occurredAt: DateTime.utc(2026),
        kind: LocalCashierCommandKind.start,
        payload: {},
      ),
    );
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  setUp(() {
    store = _Store();
    repo = _Repo();
    cubit = OfflineWorkspaceCubit(store);
    projection = {
      'authority': {'online_requested': false, 'permit_id': 'permit'},
      'shift': {'id': 'shift'},
      'bootstrap': {'protocol_version': 2},
      'outbox': [],
      'bookings': {},
      'rooms': {},
      'products': {},
      'sync_conflicts': {},
    };
    when(() => store.deviceId()).thenAnswer((_) async => 'device');
    when(() => store.open('actor', 'lounge')).thenAnswer((_) async => repo);
    when(() => repo.snapshot()).thenAnswer((_) async => Right(projection));
    when(() => repo.execute(any())).thenAnswer((_) async => const Right({}));
    when(() => repo.synchronize()).thenAnswer(
      (_) async =>
          const Right(CashierSyncResult(appliedCount: 0, pendingCount: 0)),
    );
    when(
      () => repo.bootstrap(
        deviceId: any(named: 'deviceId'),
        mode: any(named: 'mode'),
      ),
    ).thenAnswer((_) async => const Right({}));
  });
  tearDown(() => cubit.close());
  test('loads local projection without requiring bootstrap HTTP', () async {
    await cubit.load('actor', 'lounge');
    expect(cubit.state.canOperate, true);
    verifyNever(
      () => repo.bootstrap(
        deviceId: any(named: 'deviceId'),
        mode: any(named: 'mode'),
      ),
    );
  });
  test(
    'failed synchronization preserves queued work and visible error',
    () async {
      projection['outbox'] = [
        {'id': 'pending'},
      ];
      await cubit.load('actor', 'lounge');
      when(() => repo.synchronize()).thenAnswer(
        (_) async => const Left(NetworkFailure('offline_cashier.sync_failed')),
      );
      await cubit.synchronize();
      expect(cubit.state.pending, 1);
      expect(cubit.state.error, 'offline_cashier.sync_failed');
      expect(cubit.state.busy, false);
    },
  );
  test('double action while pending sends only one local command', () async {
    await cubit.load('actor', 'lounge');
    final pending = Completer<Either<Failure, Map<String, dynamic>>>();
    when(() => repo.execute(any())).thenAnswer((_) => pending.future);
    final first = cubit.execute(LocalCashierCommandKind.start, 'booking', {});
    await cubit.execute(LocalCashierCommandKind.start, 'booking', {});
    verify(() => repo.execute(any())).called(1);
    pending.complete(const Right({}));
    await first;
    expect(cubit.state.busy, false);
  });
  test('online projection cannot submit local writes', () async {
    projection['authority']['online_requested'] = true;
    await cubit.load('actor', 'lounge');
    await cubit.execute(LocalCashierCommandKind.start, 'booking', {});
    verifyNever(() => repo.execute(any()));
    expect(cubit.state.error, 'offline_cashier.bootstrap_required');
  });
  test(
    'conflict blocks reopening online even when sync returns a result',
    () async {
      projection['sync_conflicts'] = {
        'one': {'code': 'ROOM_CONFLICT'},
      };
      await cubit.load('actor', 'lounge');
      await cubit.resumeOnline();
      verifyNever(
        () => repo.bootstrap(
          deviceId: any(named: 'deviceId'),
          mode: any(named: 'mode'),
        ),
      );
      expect(cubit.state.error, 'offline_cashier.release_pending_operations');
    },
  );
  test('resume online synchronizes before a new complete bootstrap', () async {
    await cubit.load('actor', 'lounge');
    await cubit.resumeOnline();
    verifyInOrder([
      () => repo.synchronize(),
      () => repo.snapshot(),
      () => repo.bootstrap(
        deviceId: 'device',
        mode: CashierConnectionMode.online,
      ),
    ]);
  });
  test(
    'scope switch discards late operations without keeping loading',
    () async {
      await cubit.load('actor', 'lounge');
      final pending = Completer<Either<Failure, Map<String, dynamic>>>();
      when(() => repo.execute(any())).thenAnswer((_) => pending.future);
      final old = cubit.execute(LocalCashierCommandKind.start, 'booking', {});
      final second = _Repo();
      when(
        () => store.open('other', 'other-lounge'),
      ).thenAnswer((_) async => second);
      when(
        () => second.snapshot(),
      ).thenAnswer((_) async => const Right({'bookings': {}, 'outbox': []}));
      await cubit.load('other', 'other-lounge');
      pending.complete(const Left(CacheFailure('old-error')));
      await old;
      expect(cubit.state.error, isNull);
      expect(cubit.state.busy, false);
      expect(cubit.state.prepared, false);
    },
  );
  test('uncertain release preserves paused state and requires retry', () async {
    await cubit.load('actor', 'lounge');
    when(() => repo.releaseWriter()).thenAnswer((_) async {
      projection['writer_release'] = {'status': 'pending'};
      return const Left(NetworkFailure('offline_cashier.release_unavailable'));
    });
    await cubit.release();
    expect(cubit.state.canOperate, false);
    expect(cubit.state.error, 'offline_cashier.release_unavailable');
  });

  test(
    'presentation uses final server receipt without modifying local financial history',
    () async {
      projection['bookings'] = {
        'b': {'id': 'b', 'paid_minor': 100, 'sync_status': 'pending'},
      };
      projection['receipts'] = {
        'op': {'booking_id': 'b', 'sequence': 3},
      };
      projection['server_bookings'] = {
        'b': {'last_sequence': 3, 'paid_minor': 200},
      };
      await cubit.load('actor', 'lounge');
      expect(cubit.state.visibleBookings['b']['paid_minor'], 200);
      expect(cubit.state.visibleBookings['b']['sync_status'], 'synced');
      expect(cubit.state.snapshot['bookings']['b']['paid_minor'], 100);
    },
  );
  test(
    'late server receipt does not overwrite later local operation in the presentation',
    () async {
      projection['bookings'] = {
        'b': {'id': 'b', 'paid_minor': 200, 'sync_status': 'pending'},
      };
      projection['receipts'] = {
        'op': {'booking_id': 'b', 'sequence': 3},
      };
      projection['server_bookings'] = {
        'b': {'last_sequence': 2, 'paid_minor': 100},
      };
      await cubit.load('actor', 'lounge');
      expect(cubit.state.visibleBookings['b']['paid_minor'], 200);
      expect(cubit.state.visibleBookings['b']['sync_status'], 'pending');
    },
  );
  for (final language in ['ar', 'en']) {
    for (final width in [360.0, 600.0, 768.0, 1024.0, 1440.0]) {
      testWidgets('offline workspace $language $width at 1.6 text scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final login = _Login();
        when(() => login.state).thenReturn(
          const LoginState(
            user: UserEntity(
              id: 'actor',
              name: 'Test',
              email: 'test@example.invalid',
              role: UserRole.cashier,
              loungeId: 'lounge',
            ),
          ),
        );
        when(() => login.stream).thenAnswer((_) => const Stream.empty());
        projection['bookings'] = {
          'booking': {
            'id': 'booking',
            'room_id': 'room',
            'customer_name': 'عميل اختبار',
            'status': 'in_progress',
            'offline_supported': true,
            'start_ms': 1791111600000,
            'end_ms': 1791115200000,
            'total_minor': 15000,
            'paid_minor': 5000,
            'sync_status': 'pending',
          },
        };
        projection['rooms'] = {
          'room': {'name': 'غرفة اختبار'},
        };
        await cubit.load('actor', 'lounge');
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('ar'), Locale('en')],
            startLocale: Locale(language),
            saveLocale: false,
            path: 'assets/translations',
            assetLoader: const LocalTranslationsLoader(),
            child: ScreenUtilInit(
              designSize: const Size(1440, 900),
              builder: (context, _) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 1000),
                    textScaler: const TextScaler.linear(1.6),
                  ),
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider<LoginCubit>.value(value: login),
                      BlocProvider<OfflineWorkspaceCubit>.value(value: cubit),
                    ],
                    child: const OfflineWorkspacePage(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(OfflineWorkspacePage), findsOneWidget);
      });
    }
  }
  testWidgets('fresh device requests online without entering offline mode', (
    tester,
  ) async {
    projection = {'bookings': {}, 'outbox': []};
    final login = _Login();
    when(() => login.state).thenReturn(
      const LoginState(
        user: UserEntity(
          id: 'actor',
          name: 'Test',
          email: 'test@example.invalid',
          role: UserRole.cashier,
          loungeId: 'lounge',
        ),
      ),
    );
    when(() => login.stream).thenAnswer((_) => const Stream.empty());
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
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
            home: MultiBlocProvider(
              providers: [
                BlocProvider<LoginCubit>.value(value: login),
                BlocProvider<OfflineWorkspaceCubit>.value(value: cubit),
              ],
              child: const OfflineWorkspacePage(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(cubit.state.prepared, false);
    final resume = find.widgetWithText(AppButton, 'Resume online reservations');
    expect(tester.widget<AppButton>(resume).onPressed, isNotNull);
    await tester.tap(resume);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Confirm'));
    await tester.pumpAndSettle();
    verify(
      () => repo.bootstrap(
        deviceId: 'device',
        mode: CashierConnectionMode.online,
      ),
    ).called(1);
    verifyNever(
      () => repo.bootstrap(
        deviceId: any(named: 'deviceId'),
        mode: CashierConnectionMode.offline,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
