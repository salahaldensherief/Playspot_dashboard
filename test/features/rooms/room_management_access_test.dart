import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/categories/presentation/categories/category_cubit.dart';
import 'package:play_spot_dashboard/features/permissions/data/models/permission_item_model.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/get_role_permissions_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/get_user_permissions_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/update_role_permission_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/widgets/room_management_header.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/widgets/rooms_data_table.dart';
import '../../support/local_translations_loader.dart';
import '../../support/mock_permissions_repository.dart';

class _Login extends Mock implements LoginCubit {}

class _Rooms extends Mock implements RoomCubit {}

class _Categories extends Mock implements CategoryCubit {}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final language in ['ar', 'en']) {
    for (final width in [360.0, 1440.0]) {
      for (final manage in [false, true]) {
        testWidgets('room controls $language $width manage=$manage', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = MockPermissionsRepository();
          when(
            () => repository.getUserPermissions(loungeId: 'venue'),
          ).thenAnswer(
            (_) async => Right([
              for (final key in ['rooms_view', if (manage) 'rooms_manage'])
                PermissionItemModel(
                  key: key,
                  nameAr: '',
                  nameEn: '',
                  descriptionAr: '',
                  descriptionEn: '',
                  category: '',
                  isEnabled: true,
                ),
            ]),
          );
          final permissions = PermissionsCubit(
            getRolePermissionsUseCase: GetRolePermissionsUseCase(repository),
            getUserPermissionsUseCase: GetUserPermissionsUseCase(repository),
            updateRolePermissionUseCase: UpdateRolePermissionUseCase(
              repository,
            ),
          );
          addTearDown(permissions.close);
          await permissions.loadUserPermissions(
            'cashier',
            loungeId: 'venue',
            userId: 'operator',
          );
          final login = _Login();
          when(() => login.state).thenReturn(
            const LoginState(
              user: UserEntity(
                id: 'operator',
                email: '',
                name: '',
                role: UserRole.cashier,
                loungeId: 'venue',
              ),
            ),
          );
          when(() => login.stream).thenAnswer((_) => const Stream.empty());
          final rooms = _Rooms();
          when(() => rooms.stream).thenAnswer((_) => const Stream.empty());
          final categories = _Categories();
          when(() => categories.stream).thenAnswer((_) => const Stream.empty());
          await tester.pumpWidget(
            EasyLocalization(
              supportedLocales: const [Locale('ar'), Locale('en')],
              startLocale: Locale(language),
              saveLocale: false,
              path: 'assets/translations',
              assetLoader: const LocalTranslationsLoader(),
              child: ScreenUtilInit(
                designSize: const Size(1440, 900),
                builder: (context, child) => MaterialApp(
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  home: MultiBlocProvider(
                    providers: [
                      BlocProvider<LoginCubit>.value(value: login),
                      BlocProvider<PermissionsCubit>.value(value: permissions),
                      BlocProvider<RoomCubit>.value(value: rooms),
                      BlocProvider<CategoryCubit>.value(value: categories),
                    ],
                    child: Scaffold(
                      body: MediaQuery(
                        data: MediaQueryData(
                          size: Size(width, 1000),
                          textScaler: const TextScaler.linear(1.6),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const RoomManagementHeader(loungeId: 'venue'),
                              const RoomsDataTable(
                                rooms: [
                                  RoomEntity(
                                    id: 'room',
                                    loungeId: 'venue',
                                    nameAr: 'غرفة الألعاب',
                                    nameEn: 'Gaming room',
                                    hourlyRateSingle: 60,
                                    hourlyRateMulti: 80,
                                    isAvailable: false,
                                    status: RoomStatusEnum.occupied,
                                    images: [],
                                    featuresAr: [],
                                    featuresEn: [],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byIcon(Icons.edit_outlined),
            manage ? findsOneWidget : findsNothing,
          );
          expect(
            find.byIcon(Icons.delete_outline),
            manage ? findsOneWidget : findsNothing,
          );
          expect(
            find.byIcon(Icons.add),
            manage ? findsOneWidget : findsNothing,
          );
          expect(find.byType(Switch), manage ? findsOneWidget : findsNothing);
          if (manage) {
            expect(
              tester.widget<Switch>(find.byType(Switch)).onChanged,
              isNull,
            );
          }
          expect(
            find.text(language == 'ar' ? 'غرفة الألعاب' : 'Gaming room'),
            findsWidgets,
          );
          expect(find.text('Available'), findsNothing);
          expect(
            find.text(language == 'ar' ? 'مشغولة' : 'OCCUPIED'),
            findsOneWidget,
          );
          verifyNever(
            () => rooms.toggleWalkInStatus('room', RoomStatusEnum.occupied),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
