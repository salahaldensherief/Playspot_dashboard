import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_control_actions.dart';
import 'package:play_spot_dashboard/features/permissions/data/models/permission_item_model.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/get_role_permissions_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/get_user_permissions_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/update_role_permission_use_case.dart';
import '../../support/mock_login_cubit.dart';
import '../../support/mock_permissions_repository.dart';

void main() {
  testWidgets(
    'cashier actions react to revocation and cannot reuse a logged-out identity',
    (tester) async {
      final repository = MockPermissionsRepository();
      final permission = PermissionItemModel(
        key: 'sessions_control',
        nameAr: '',
        nameEn: '',
        descriptionAr: '',
        descriptionEn: '',
        category: '',
        isEnabled: true,
      );
      when(
        () => repository.getUserPermissions(loungeId: 'l'),
      ).thenAnswer((_) async => Right([permission]));
      final permissions = PermissionsCubit(
        getRolePermissionsUseCase: GetRolePermissionsUseCase(repository),
        getUserPermissionsUseCase: GetUserPermissionsUseCase(repository),
        updateRolePermissionUseCase: UpdateRolePermissionUseCase(repository),
      );
      await permissions.loadUserPermissions(
        'cashier',
        loungeId: 'l',
        userId: 'u',
      );
      final login = MockLoginCubit();
      final authEvents = StreamController<LoginState>.broadcast();
      const user = UserEntity(
        id: 'u',
        email: '',
        name: '',
        role: UserRole.cashier,
      );
      var auth = const LoginState(
        status: LoginStatus.authenticated,
        user: user,
      );
      when(() => login.state).thenAnswer((_) => auth);
      when(() => login.stream).thenAnswer((_) => authEvents.stream);
      final booking = Booking(
        id: 'b',
        userId: 'customer',
        loungeId: 'l',
        roomId: 'r',
        date: DateTime.now(),
        startTime: '10:00',
        endTime: '11:00',
        status: BookingStatus.inProgress,
        totalPrice: 100,
      );
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(1920, 1080),
          builder: (_, child) => MultiBlocProvider(
            providers: [
              BlocProvider<LoginCubit>.value(value: login),
              BlocProvider<PermissionsCubit>.value(value: permissions),
            ],
            child: MaterialApp(
              home: Scaffold(body: SessionControlActions(booking: booking)),
            ),
          ),
        ),
      );
      await tester.pump();
      Iterable<AppButton> buttons() =>
          tester.widgetList<AppButton>(find.byType(AppButton));
      expect(
        buttons().take(4).every((button) => button.onPressed != null),
        isTrue,
      );
      expect(
        buttons().skip(4).every((button) => button.onPressed == null),
        isTrue,
      );
      when(
        () => repository.getUserPermissions(loungeId: 'l'),
      ).thenAnswer((_) async => Right([permission.copyWith(isEnabled: false)]));
      await permissions.loadUserPermissions(
        'cashier',
        loungeId: 'l',
        userId: 'u',
      );
      await tester.pump();
      expect(buttons().every((button) => button.onPressed == null), isTrue);
      when(
        () => repository.getUserPermissions(loungeId: 'l'),
      ).thenAnswer((_) async => Right([permission]));
      await permissions.loadUserPermissions(
        'cashier',
        loungeId: 'l',
        userId: 'u',
      );
      await tester.pump();
      auth = const LoginState(status: LoginStatus.unauthenticated);
      authEvents.add(auth);
      await tester.pump();
      expect(buttons().every((button) => button.onPressed == null), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await authEvents.close();
      await permissions.close();
    },
  );
}
