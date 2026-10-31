import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/art_core/layouts/top_bar/top_bar_lounge_status_toggle.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_state.dart';
import 'package:play_spot_dashboard/features/permissions/domain/entities/permission_item_entity.dart';
import 'package:play_spot_dashboard/features/permissions/data/models/permission_item_model.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/get_role_permissions_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/get_user_permissions_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/update_role_permission_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../../support/local_translations_loader.dart';
import '../../support/mock_permissions_repository.dart';

class _Login extends Mock implements LoginCubit {}

class _Lounges extends Mock implements LoungeCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final role in [UserRole.owner, UserRole.manager, UserRole.cashier]) {
    testWidgets('${role.name} status control reacts to grants and revocation', (
      tester,
    ) async {
      final repository = MockPermissionsRepository();
      final pending = Completer<Either<Failure, List<PermissionItemEntity>>>();
      when(
        () => repository.getUserPermissions(loungeId: 'venue'),
      ).thenAnswer((_) => pending.future);
      final permissions = PermissionsCubit(
        getRolePermissionsUseCase: GetRolePermissionsUseCase(repository),
        getUserPermissionsUseCase: GetUserPermissionsUseCase(repository),
        updateRolePermissionUseCase: UpdateRolePermissionUseCase(repository),
      );
      addTearDown(permissions.close);
      final load = permissions.loadUserPermissions(
        role.name,
        loungeId: 'venue',
        userId: 'operator',
      );
      final login = _Login();
      when(() => login.state).thenReturn(
        LoginState(
          user: UserEntity(
            id: 'operator',
            email: '',
            name: 'Operator',
            role: role,
            loungeId: 'venue',
          ),
        ),
      );
      when(() => login.stream).thenAnswer((_) => const Stream.empty());
      final lounges = _Lounges();
      when(() => lounges.state).thenReturn(
        const LoungeState(
          lounges: [
            Lounge(
              id: 'venue',
              name: 'Venue',
              imageUrl: '',
              opensAt: '09:00',
              closesAt: '03:00',
              isOpen: false,
            ),
          ],
        ),
      );
      when(() => lounges.stream).thenAnswer((_) => const Stream.empty());
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: const Locale('en'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const LocalTranslationsLoader(),
          child: Builder(
            builder: (context) => ScreenUtilInit(
              designSize: const Size(1440, 1024),
              builder: (context, child) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: MultiBlocProvider(
                  providers: [
                    BlocProvider<LoginCubit>.value(value: login),
                    BlocProvider<LoungeCubit>.value(value: lounges),
                    BlocProvider<PermissionsCubit>.value(value: permissions),
                  ],
                  child: const Scaffold(body: TopBarLoungeStatusToggle()),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsNothing);
      final grant = PermissionItemModel(
        key: 'lounge_toggle_status',
        nameAr: '',
        nameEn: '',
        descriptionAr: '',
        descriptionEn: '',
        category: '',
        isEnabled: true,
      );
      pending.complete(Right([grant]));
      await load;
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      when(
        () => repository.getUserPermissions(loungeId: 'venue'),
      ).thenAnswer((_) async => const Right([]));
      await permissions.loadUserPermissions(
        role.name,
        loungeId: 'venue',
        userId: 'operator',
      );
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsNothing);
      when(
        () => repository.getUserPermissions(loungeId: 'venue'),
      ).thenAnswer((_) async => Right([grant]));
      await permissions.loadUserPermissions(
        role.name,
        loungeId: 'venue',
        userId: 'different-operator',
      );
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
