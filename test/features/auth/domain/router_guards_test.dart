import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/router/router_guards.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';

class _MockBuildContext extends Mock implements BuildContext {}

class _MockGoRouterState extends Mock implements GoRouterState {}

class _MockLoginCubit extends Mock implements LoginCubit {}

UserEntity _user(UserRole role, {bool setupCompleted = true}) {
  return UserEntity(
    id: 'u1',
    email: 'test@playspot.gg',
    name: 'Tester',
    role: role,
    isSetupCompleted: setupCompleted,
  );
}

void main() {
  late _MockBuildContext context;
  late _MockGoRouterState state;
  late _MockLoginCubit authCubit;

  setUpAll(() {
    registerFallbackValue(_MockBuildContext());
  });

  setUp(() {
    context = _MockBuildContext();
    state = _MockGoRouterState();
    authCubit = _MockLoginCubit();
  });

  String? guard({
    required LoginStatus status,
    UserEntity? user,
    Lounge? lounge,
    String location = RouterKeys.root,
  }) {
    when(() => state.matchedLocation).thenReturn(location);
    when(() => authCubit.state).thenReturn(LoginState(
      status: status,
      user: user,
      userLounge: lounge,
    ));
    return RouterGuards.redirect(context, state, authCubit);
  }

  group('RouterGuards.redirect', () {
    test('allows navigation while auth status is initial', () {
      expect(guard(status: LoginStatus.initial), isNull);
    });

    test('allows navigation while checking session', () {
      expect(guard(status: LoginStatus.checking), isNull);
    });

    test('redirects unauthenticated users to login', () {
      final result = guard(status: LoginStatus.unauthenticated);
      expect(result, RouterKeys.login);
    });

    test('keeps unauthenticated users on the login screen', () {
      final result = guard(
        status: LoginStatus.unauthenticated,
        location: RouterKeys.login,
      );
      expect(result, isNull);
    });

    test('bounces regular users (non-staff) back to login', () {
      final result = guard(
        status: LoginStatus.authenticated,
        user: _user(UserRole.user),
      );
      expect(result, RouterKeys.login);
    });

    test('sends super admin to super-admin dashboard from login/root', () {
      final result = guard(
        status: LoginStatus.authenticated,
        user: _user(UserRole.superAdmin),
        location: RouterKeys.login,
      );
      expect(result, RouterKeys.superAdminDashboard);
    });

    test('sends staff to lounge dashboard from root', () {
      final result = guard(
        status: LoginStatus.authenticated,
        user: _user(UserRole.cashier),
        location: RouterKeys.root,
      );
      expect(result, RouterKeys.loungeAdminDashboard);
    });

    test('forces owners with incomplete setup into onboarding', () {
      final result = guard(
        status: LoginStatus.authenticated,
        user: _user(UserRole.owner, setupCompleted: false),
        location: RouterKeys.loungeAdminDashboard,
      );
      expect(result, RouterKeys.loungeOnboarding);
    });

    test('keeps owners on onboarding while setup is incomplete', () {
      final result = guard(
        status: LoginStatus.authenticated,
        user: _user(UserRole.owner, setupCompleted: false),
        location: RouterKeys.loungeOnboarding,
      );
      expect(result, isNull);
    });

    test('sends pending-lounge owners to KYC pending screen', () {
      final result = guard(
        status: LoginStatus.authenticated,
        user: _user(UserRole.owner),
        lounge: Lounge(
          id: 'l1',
          name: 'Lounge',
          imageUrl: '',
          opensAt: '10:00',
          closesAt: '23:00',
          status: 'pending',
        ),
        location: RouterKeys.loungeAdminDashboard,
      );
      expect(result, RouterKeys.kycPending);
    });

    test('lets active-lounge owners proceed normally', () {
      final result = guard(
        status: LoginStatus.authenticated,
        user: _user(UserRole.owner),
        lounge: Lounge(
          id: 'l1',
          name: 'Lounge',
          imageUrl: '',
          opensAt: '10:00',
          closesAt: '23:00',
          status: 'active',
        ),
        location: RouterKeys.loungeAdminDashboard,
      );
      expect(result, isNull);
    });

    test('blocks non-super-admins from super-admin routes', () {
      final result = guard(
        status: LoginStatus.authenticated,
        user: _user(UserRole.manager),
        location: RouterKeys.superAdminLounges,
      );
      expect(result, RouterKeys.loungeAdminDashboard);
    });

    test('blocks cashiers from reviews route via permission fallback', () {
      final result = guard(
        status: LoginStatus.authenticated,
        user: _user(UserRole.cashier),
        location: RouterKeys.loungeAdminReviews,
      );
      expect(result, contains('unauthorized=true'));
    });

    test('allows cashiers on the lounge dashboard', () {
      final result = guard(
        status: LoginStatus.authenticated,
        user: _user(UserRole.cashier),
        location: RouterKeys.loungeAdminDashboard,
      );
      expect(result, isNull);
    });
  });
}
