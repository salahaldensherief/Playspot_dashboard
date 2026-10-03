import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/router/router_guards.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/permissions/domain/entities/permission_item_entity.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/get_role_permissions_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/get_user_permissions_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/domain/use_cases/update_role_permission_use_case.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_state.dart';
import '../../../support/mock_permissions_repository.dart';

class _Auth extends Mock implements LoginCubit {}

class _Context extends Mock implements BuildContext {}

class _Route extends Mock implements GoRouterState {}

const actor = UserEntity(
  id: 'operator',
  email: '',
  name: '',
  role: UserRole.cashier,
  loungeId: 'venue',
);
const venue = Lounge(
  id: 'venue',
  name: '',
  imageUrl: '',
  opensAt: '10:00',
  closesAt: '23:00',
  status: 'active',
);
const roomGrant = PermissionItemEntity(
  key: 'rooms_view',
  nameAr: '',
  nameEn: '',
  descriptionAr: '',
  descriptionEn: '',
  category: '',
  isEnabled: true,
);

void main() {
  late MockPermissionsRepository repository;
  late PermissionsCubit permissions;
  late _Auth auth;
  setUp(() {
    repository = MockPermissionsRepository();
    permissions = PermissionsCubit(
      getRolePermissionsUseCase: GetRolePermissionsUseCase(repository),
      getUserPermissionsUseCase: GetUserPermissionsUseCase(repository),
      updateRolePermissionUseCase: UpdateRolePermissionUseCase(repository),
    );
    GetIt.I.registerSingleton<PermissionsCubit>(permissions);
    auth = _Auth();
    when(() => auth.state).thenReturn(
      const LoginState(
        status: LoginStatus.authenticated,
        user: actor,
        userLounge: venue,
      ),
    );
  });
  tearDown(() async {
    await GetIt.I.unregister<PermissionsCubit>();
    await permissions.close();
  });
  String? redirect(String location) {
    final route = _Route();
    when(() => route.uri).thenReturn(Uri.parse(location));
    when(() => route.matchedLocation).thenReturn(Uri.parse(location).path);
    return RouterGuards.redirect(
      _Context(),
      route,
      auth,
      permissionCubit: permissions,
    );
  }

  String waiting(String from) => Uri(
    path: RouterKeys.accessLoading,
    queryParameters: {'from': from},
  ).toString();
  Future<void> load(List<PermissionItemEntity> grants) async {
    when(
      () => repository.getUserPermissions(loungeId: 'venue'),
    ).thenAnswer((_) async => Right(grants));
    await permissions.loadUserPermissions(
      'cashier',
      userId: 'operator',
      loungeId: 'venue',
    );
  }

  test(
    'cold deep link waits, preserves query, then admits only after grants',
    () async {
      const target = '/lounge-admin/rooms?filter=vip';
      expect(redirect(target), waiting(target));
      final pending = Completer<Either<Failure, List<PermissionItemEntity>>>();
      when(
        () => repository.getUserPermissions(loungeId: 'venue'),
      ).thenAnswer((_) => pending.future);
      final request = permissions.loadUserPermissions(
        'cashier',
        userId: 'operator',
        loungeId: 'venue',
      );
      expect(permissions.state.accessStatus, PermissionsStatus.loading);
      expect(redirect(waiting(target)), isNull);
      expect(actor.canEditSetup, isFalse);
      pending.complete(const Right([roomGrant]));
      await request;
      expect(redirect(waiting(target)), target);
      expect(redirect(target), isNull);
    },
  );
  test(
    'actual missing grant is denied after loading, never granted by waiting',
    () async {
      await load([]);
      expect(
        redirect(RouterKeys.loungeAdminRooms),
        '${RouterKeys.loungeAdminDashboard}?unauthorized=true',
      );
      expect(
        redirect(waiting(RouterKeys.loungeAdminRooms)),
        RouterKeys.loungeAdminRooms,
      );
      expect(
        redirect(RouterKeys.loungeAdminRooms),
        contains('unauthorized=true'),
      );
    },
  );
  test('menu-only access cannot open room management', () async {
    await load([
      const PermissionItemEntity(
        key: 'menu_view',
        nameAr: '',
        nameEn: '',
        descriptionAr: '',
        descriptionEn: '',
        category: '',
        isEnabled: true,
      ),
    ]);
    expect(redirect(RouterKeys.loungeAdminExtras), isNull);
    expect(
      redirect(RouterKeys.loungeAdminRooms),
      contains('unauthorized=true'),
    );
  });
  test('revoked room access is enforced on the current route', () async {
    await load([roomGrant]);
    expect(redirect(RouterKeys.loungeAdminRooms), isNull);
    await load([]);
    expect(
      redirect(RouterKeys.loungeAdminRooms),
      contains('unauthorized=true'),
    );
  });
  test('loading lounge cannot show KYC rejection or build protected route', () {
    when(() => auth.state).thenReturn(
      const LoginState(
        status: LoginStatus.authenticated,
        user: actor,
        isLoadingLounge: true,
      ),
    );
    expect(
      redirect(RouterKeys.loungeAdminRooms),
      waiting(RouterKeys.loungeAdminRooms),
    );
    expect(redirect(waiting(RouterKeys.loungeAdminRooms)), isNull);
  });
  test(
    'failed access remains on retry screen, no authorization fallback',
    () async {
      when(
        () => repository.getUserPermissions(loungeId: 'venue'),
      ).thenAnswer((_) async => const Left(ServerFailure('denied')));
      await permissions.loadUserPermissions(
        'cashier',
        userId: 'operator',
        loungeId: 'venue',
      );
      expect(permissions.state.accessStatus, PermissionsStatus.failure);
      expect(
        redirect(RouterKeys.loungeAdminRooms),
        waiting(RouterKeys.loungeAdminRooms),
      );
      expect(redirect(waiting(RouterKeys.loungeAdminRooms)), isNull);
      expect(actor.canEditSetup, isFalse);
    },
  );
  test(
    'another lounge cannot reuse loaded access and external return URL is ignored',
    () async {
      await load([roomGrant]);
      expect(
        redirect(waiting('https://example.invalid/path')),
        RouterKeys.loungeAdminDashboard,
      );
      permissions.setActiveLoungeId('other');
      expect(
        redirect(RouterKeys.loungeAdminRooms),
        waiting(RouterKeys.loungeAdminRooms),
      );
      expect(actor.canEditSetup, isFalse);
    },
  );
  test(
    'permission editor loading is independent from current user access',
    () async {
      await load([roomGrant]);
      final editor = Completer<Either<Failure, List<PermissionItemEntity>>>();
      when(
        () => repository.getRolePermissions('cashier', loungeId: 'venue'),
      ).thenAnswer((_) => editor.future);
      final request = permissions.fetchPermissions(
        'cashier',
        loungeId: 'venue',
      );
      expect(permissions.state.status, PermissionsStatus.loading);
      expect(permissions.state.accessStatus, PermissionsStatus.success);
      expect(redirect(RouterKeys.loungeAdminRooms), isNull);
      editor.complete(const Right([]));
      await request;
    },
  );

  test(
    'multiple shell initializers share pending and completed access requests',
    () async {
      final pending = Completer<Either<Failure, List<PermissionItemEntity>>>();
      when(
        () => repository.getUserPermissions(loungeId: 'venue'),
      ).thenAnswer((_) => pending.future);
      final first = permissions.ensureUserPermissions(
        'cashier',
        loungeId: 'venue',
        userId: 'operator',
      );
      await permissions.ensureUserPermissions(
        'cashier',
        loungeId: 'venue',
        userId: 'operator',
      );
      verify(() => repository.getUserPermissions(loungeId: 'venue')).called(1);
      pending.complete(const Right([roomGrant]));
      await first;
      await permissions.ensureUserPermissions(
        'cashier',
        loungeId: 'venue',
        userId: 'operator',
      );
      verifyNever(() => repository.getUserPermissions(loungeId: 'venue'));
      expect(redirect(RouterKeys.loungeAdminRooms), isNull);
      await load([]);
      expect(
        redirect(RouterKeys.loungeAdminRooms),
        contains('unauthorized=true'),
      );
    },
  );
}
