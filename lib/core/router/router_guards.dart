import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';

import '../../features/permissions/presentation/cubit/permissions_cubit.dart';

class RouterGuards {
  static String _requestedLocation(GoRouterState state, UserEntity user) {
    final fallback = user.role == UserRole.superAdmin
        ? RouterKeys.superAdminDashboard
        : RouterKeys.loungeAdminDashboard;
    final requested = state.matchedLocation == RouterKeys.accessLoading
        ? state.uri.queryParameters['from']
        : state.uri.toString();
    final uri = Uri.tryParse(requested ?? '');
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        !(uri.path.startsWith('/lounge-admin/') ||
            uri.path.startsWith('/super-admin/') ||
            uri.path == RouterKeys.profile)) {
      return fallback;
    }
    return uri.toString();
  }

  static String _accessLoadingLocation(GoRouterState state, UserEntity user) =>
      Uri(
        path: RouterKeys.accessLoading,
        queryParameters: {'from': _requestedLocation(state, user)},
      ).toString();

  static String? redirect(
    BuildContext context,
    GoRouterState state,
    LoginCubit authCubit, {
    PermissionsCubit? permissionCubit,
  }) {
    final authState = authCubit.state;
    final bool isLoggingIn = state.matchedLocation == RouterKeys.login;
    final user = authState.user;

    if (authState.status == LoginStatus.profileFailure) {
      return state.matchedLocation == RouterKeys.accessLoading
          ? null
          : Uri(
              path: RouterKeys.accessLoading,
              queryParameters: {'from': state.uri.toString()},
            ).toString();
    }

    if (authState.status == LoginStatus.initial ||
        authState.status == LoginStatus.checking) {
      return null;
    }

    final bool isAuthenticated =
        authState.status == LoginStatus.authenticated ||
        authState.status == LoginStatus.success;

    if (!isAuthenticated) {
      return isLoggingIn ? null : RouterKeys.login;
    }

    // Authenticated but profile not loaded yet — hold navigation until refresh.
    if (user == null) return null;

    final bool isStaffUser = user.isStaff;
    final bool isLoungeOwner = user.isOwner;
    final bool isSuperAdmin = user.role == UserRole.superAdmin;
    final rawPermissionRole = user.rawRole?.trim();
    final permissionRole =
        rawPermissionRole == null || rawPermissionRole.isEmpty
        ? user.role.name
        : rawPermissionRole;

    // Security Guard: Only SuperAdmins and Lounge Staff are allowed to access the Dashboard
    if (!user.isActive || user.isBanned || (!isSuperAdmin && !isStaffUser)) {
      return isLoggingIn ? null : RouterKeys.login;
    }

    final bool isOnboardingPath =
        state.matchedLocation == RouterKeys.loungeOnboarding;
    final bool isKycPendingPath =
        state.matchedLocation == RouterKeys.kycPending;

    final lounge = authState.userLounge;
    final bool isLoungePending =
        lounge == null || lounge.status != 'active' || !lounge.isActive;

    // 1. Only Lounge Owners who haven't completed setup need Onboarding
    if (!isSuperAdmin && isLoungeOwner && !user.isSetupCompleted) {
      if (!isOnboardingPath) return RouterKeys.loungeOnboarding;
      return null;
    }

    if (!isSuperAdmin &&
        (authState.isLoadingLounge || authState.loungeLoadError != null)) {
      return state.matchedLocation == RouterKeys.accessLoading
          ? null
          : _accessLoadingLocation(state, user);
    }

    // 2. Lounge Owners whose lounge/KYC is still pending approval go to KYC Pending Screen
    if (!isSuperAdmin && isStaffUser && isLoungePending) {
      if (!isKycPendingPath) return RouterKeys.kycPending;
      return null;
    }

    if (permissionCubit != null &&
        !permissionCubit.hasLoadedAccess(
          permissionRole,
          user.id,
          user.loungeId,
        )) {
      return state.matchedLocation == RouterKeys.accessLoading
          ? null
          : _accessLoadingLocation(state, user);
    }
    if (state.matchedLocation == RouterKeys.accessLoading) {
      return _requestedLocation(state, user);
    }

    // Staff do not own venue setup. An approved lounge loaded after sign-in
    // must release them from the temporary pending screen even when their
    // personal setup flag is false. Keep pending/disabled venues gated above.
    if (isOnboardingPath || isKycPendingPath) {
      if (isSuperAdmin) return RouterKeys.superAdminDashboard;
      if (!isLoungePending && (!isLoungeOwner || user.isSetupCompleted)) {
        return RouterKeys.loungeAdminDashboard;
      }
    }

    if (isOnboardingPath && !isLoungeOwner) {
      return RouterKeys.loungeAdminDashboard;
    }

    if (isLoggingIn || state.matchedLocation == RouterKeys.root) {
      if (isSuperAdmin) return RouterKeys.superAdminDashboard;
      if (isStaffUser) return RouterKeys.loungeAdminDashboard;
    }

    final String location = state.matchedLocation;

    if (location.startsWith('/super-admin') && !isSuperAdmin) {
      return RouterKeys.loungeAdminDashboard;
    }

    final bool isStaffManagementRoute = location == RouterKeys.loungeAdminStaff;
    final bool isFinancialRoute =
        location.contains('/payouts') || location.contains('/reports');
    final bool isShiftHistoryRoute = location == RouterKeys.loungeAdminShifts;
    final bool isMarketingRoute = location == RouterKeys.loungeAdminMarketing;
    final bool isSetupRoute =
        location == RouterKeys.loungeAdminRooms ||
        location == RouterKeys.loungeAdminExtras;
    final bool isReviewsRoute = location == RouterKeys.loungeAdminReviews;

    if (isReviewsRoute && !user.canViewReviews) {
      return '${RouterKeys.loungeAdminDashboard}?unauthorized=true';
    }

    if (isStaffManagementRoute && !user.canManageStaff) {
      return '${RouterKeys.loungeAdminDashboard}?unauthorized=true';
    }

    if (isFinancialRoute && !user.canViewFinancials) {
      return '${RouterKeys.loungeAdminDashboard}?unauthorized=true';
    }

    if (isShiftHistoryRoute && !user.canViewShiftHistory) {
      return '${RouterKeys.loungeAdminDashboard}?unauthorized=true';
    }

    if (isMarketingRoute && !user.canManageMarketing) {
      return '${RouterKeys.loungeAdminDashboard}?unauthorized=true';
    }

    final canReadSetup = permissionCubit == null
        ? user.canEditSetup
        : location == RouterKeys.loungeAdminRooms
        ? ['rooms_view', 'rooms_manage'].any(
            (key) => permissionCubit.hasPermission(
              key,
              userRole: user.role.name,
              userId: user.id,
            ),
          )
        : ['menu_view', 'menu_manage_items', 'extras_update_stock'].any(
            (key) => permissionCubit.hasPermission(
              key,
              userRole: user.role.name,
              userId: user.id,
            ),
          );
    if (isSetupRoute && !canReadSetup) {
      return '${RouterKeys.loungeAdminDashboard}?unauthorized=true';
    }

    return null;
  }
}
