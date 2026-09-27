import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/get_user_permissions_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/features/permissions/domain/repositories/permissions_repository.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/get_role_permissions_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/update_role_permission_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';

class _Repository extends Mock implements PermissionsRepository {}

void main() {
  test('editing cashier permissions cannot change the current manager grants', () async {
    final repository = _Repository();
    when(() => repository.getUserPermissions(loungeId: 'lounge-a'))
      .thenAnswer((_) async => const Right([]));
    when(() => repository.getRolePermissions('cashier', loungeId: 'lounge-a'))
      .thenAnswer((_) async => const Right([]));
    when(() => repository.updateRolePermission('cashier', 'bookings.view', true, loungeId: 'lounge-a'))
      .thenAnswer((_) async => const Right(null));
    final cubit = PermissionsCubit(
      getRolePermissionsUseCase: GetRolePermissionsUseCase(repository),
      getUserPermissionsUseCase: GetUserPermissionsUseCase(repository),
      updateRolePermissionUseCase: UpdateRolePermissionUseCase(repository),
    );
    await cubit.loadUserPermissions('manager', loungeId: 'lounge-a');
    await cubit.fetchPermissions('cashier', loungeId: 'lounge-a');
    await cubit.togglePermission('cashier', 'bookings.view', true, loungeId: 'lounge-a');
    expect(cubit.state.userRole, 'manager');
    expect(cubit.state.userPermissions, isEmpty);
    await cubit.close();
  });
}
