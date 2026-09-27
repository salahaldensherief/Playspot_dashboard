import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_permissions.dart';
import 'package:play_spot_dashboard/features/permissions/data/models/permission_item_model.dart';
import 'package:play_spot_dashboard/features/permissions/domain/repositories/permissions_repository.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/get_role_permissions_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/get_user_permissions_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/update_role_permission_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';

class _Repository extends Mock implements PermissionsRepository {}

PermissionItemModel permission(String key, bool enabled) => PermissionItemModel(
  key: key, nameAr: '', nameEn: '', category: '',
  descriptionAr: '', descriptionEn: '', isEnabled: enabled);

void main() {
  late _Repository repository;
  late PermissionsCubit cubit;
  setUp(() {
    repository = _Repository();
    cubit = PermissionsCubit(
      getRolePermissionsUseCase: GetRolePermissionsUseCase(repository),
      getUserPermissionsUseCase: GetUserPermissionsUseCase(repository),
      updateRolePermissionUseCase: UpdateRolePermissionUseCase(repository));
    GetIt.I.registerSingleton<PermissionsCubit>(cubit);
  });
  tearDown(() async {
    await GetIt.I.reset();
    await cubit.close();
  });

  Future<void> load(String role, List<PermissionItemModel> values) async {
    when(() => repository.getUserPermissions(loungeId: 'lounge'))
      .thenAnswer((_) async => Right(values));
    await cubit.loadUserPermissions(role, loungeId: 'lounge', userId: 'current');
  }

  test('all roles deny before permissions arrive, including owner and super admin', () {
    for (final role in UserRole.values) {
      expect(UserPermissions(role, userId: 'current').canManageStaff, false);
      expect(UserPermissions(role, userId: 'current').can('__unknown__'), false);
    }
  });

  test('server grants and denials take precedence over privileged role', () async {
    await load('owner', [permission('staff_manage', false), permission('payouts_manage', true)]);
    const permissions = UserPermissions(UserRole.owner, userId: 'current');
    expect(permissions.canManageStaff, false);
    expect(permissions.canViewFinancials, true);
    expect(permissions.can('__unknown__'), false);
  });

  test('cashier global analytics follows server denial', () async {
    await load('cashier', [permission('analytics_view_global', false)]);
    expect(cubit.hasPermission('analytics_view_global', userRole: 'cashier', userId: 'current'), false);
  });

  test('another user, role, or unknown role cannot reuse current grants', () async {
    await load('manager', [permission('staff_manage', true)]);
    expect(cubit.hasPermission('staff_manage', userRole: 'manager', userId: 'other'), false);
    expect(cubit.hasPermission('staff_manage', userRole: 'cashier', userId: 'current'), false);
    expect(cubit.hasPermission('staff_manage', userRole: '__unknown__', userId: 'current'), false);
    expect(cubit.hasPermission('staff_manage', userRole: 'manager', userId: 'current'), true);
  });

  test('fetch failure clears previous grants', () async {
    await load('manager', [permission('staff_manage', true)]);
    when(() => repository.getUserPermissions(loungeId: 'lounge'))
      .thenAnswer((_) async => Left(ServerFailure('unavailable')));
    await cubit.loadUserPermissions('manager', loungeId: 'lounge', userId: 'current');
    expect(cubit.hasPermission('staff_manage', userRole: 'manager', userId: 'current'), false);
  });

  test('user entity supplies its identity to the permission evaluator', () async {
    await load('cashier', [permission('rooms_view_status', true)]);
    const user = UserEntity(id: 'current', email: '', name: '', role: UserRole.cashier);
    expect(user.permissions.can('rooms_view'), true);
    expect(user.copyWith(id: 'other').permissions.can('rooms_view'), false);
    expect(user.needsShift, true);
  });

  test('effective-permissions usecase returns repository success', () async {
    when(() => repository.getUserPermissions(loungeId: 'lounge'))
      .thenAnswer((_) async => Right([permission('staff_manage', false)]));
    final result = await GetUserPermissionsUseCase(repository)(loungeId: 'lounge');
    expect(result.isRight(), true);
    result.fold((_) => fail('unexpected failure'), (items) => expect(items.single.isEnabled, false));
  });

  test('effective-permissions usecase preserves repository failure', () async {
    final failure = ServerFailure('unavailable');
    when(() => repository.getUserPermissions(loungeId: 'lounge'))
      .thenAnswer((_) async => Left(failure));
    final result = await GetUserPermissionsUseCase(repository)(loungeId: 'lounge');
    result.fold((actual) => expect(actual, failure), (_) => fail('unexpected success'));
  });
}
