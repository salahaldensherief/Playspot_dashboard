import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/audit/domain/entities/audit_log_entity.dart';
import 'package:play_spot_dashboard/features/audit/domain/usecases/export_audit_logs_csv_usecase.dart';
import 'package:play_spot_dashboard/features/audit/domain/usecases/get_audit_logs_usecase.dart';
import 'package:play_spot_dashboard/features/audit/presentation/audit_cubit.dart';
import 'package:play_spot_dashboard/features/audit/presentation/audit_screen.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';

class MockLoginCubit extends Mock implements LoginCubit {}
class MockGetAuditLogsUsecase extends Mock implements GetAuditLogsUsecase {}
class MockExportAuditLogsCsvUsecase extends Mock implements ExportAuditLogsCsvUsecase {}

void main() {
  final sl = GetIt.instance;
  late MockLoginCubit mockLoginCubit;
  late MockGetAuditLogsUsecase mockGetAuditLogs;
  late MockExportAuditLogsCsvUsecase mockExportCsv;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    sl.reset();
    mockLoginCubit = MockLoginCubit();
    mockGetAuditLogs = MockGetAuditLogsUsecase();
    mockExportCsv = MockExportAuditLogsCsvUsecase();

    final user = UserEntity(
      id: 'usr-1',
      name: 'Owner',
      email: 'owner@playspot.app',
      role: UserRole.owner,
      loungeId: 'lounge-1',
    );

    when(() => mockLoginCubit.state).thenReturn(
      LoginState(status: LoginStatus.authenticated, user: user),
    );
    when(() => mockLoginCubit.stream).thenAnswer((_) => const Stream.empty());

    sl.registerLazySingleton<LoginCubit>(() => mockLoginCubit);
    sl.registerFactory<AuditCubit>(
      () => AuditCubit(
        getAuditLogsUsecase: mockGetAuditLogs,
        exportAuditLogsCsvUsecase: mockExportCsv,
      ),
    );

    registerFallbackValue(const GetAuditLogsParams(loungeId: 'lounge-1'));
    registerFallbackValue(const ExportAuditLogsParams(loungeId: 'lounge-1'));

    final tLog = AuditLogEntity(
      id: 'evt-1',
      entityType: 'booking',
      action: 'created',
      createdAt: DateTime(2026, 3, 30),
    );
    when(() => mockGetAuditLogs(any())).thenAnswer(
      (_) async => Right(AuditLogPaginatedResult(logs: [tLog], hasMore: false)),
    );
  });

  Widget buildTestableWidget(Size screenSize) {
    return EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: ScreenUtilInit(
        designSize: const Size(1440, 900),
        builder: (context, child) => MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: MaterialApp(
            home: BlocProvider<LoginCubit>.value(
              value: mockLoginCubit,
              child: const Scaffold(
                backgroundColor: AppColors.scaffoldBackground,
                body: AuditScreen(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders without overflow on Mobile screen (390x844)', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(const Size(390, 844)));
    await tester.pumpAndSettle();

    expect(find.byType(AuditScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow on Tablet screen (900x1280)', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(const Size(900, 1280)));
    await tester.pumpAndSettle();

    expect(find.byType(AuditScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow on Desktop screen (1440x900)', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(const Size(1440, 900)));
    await tester.pumpAndSettle();

    expect(find.byType(AuditScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
