import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';

class RouterGuards {
  static String? redirect(
    BuildContext context,
    GoRouterState state,
    LoginCubit authCubit,
  ) {
    final authState = authCubit.state;
    final bool isLoggingIn = state.matchedLocation == RouterKeys.login;
    final user = authState.user;

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

    if (user == null) return isLoggingIn ? null : null;

    final bool isStaffUser = user.isStaff;
    final bool isLoungeOwner = user.isOwner;
    final bool isSuperAdmin = user.role == UserRole.superAdmin;

    // Security Guard: Only SuperAdmins and Lounge Staff are allowed to access the Dashboard
    if (!isSuperAdmin && !isStaffUser) {
      return RouterKeys.login;
    }

    final bool isOnboardingPath =
        state.matchedLocation == RouterKeys.loungeOnboarding;
    final bool isKycPendingPath =
        state.matchedLocation == RouterKeys.kycPending;

    final lounge = authState.userLounge;
    final bool isLoungePending = lounge != null &&
        (lounge.status == 'pending' ||
            lounge.status == 'pending_approval' ||
            lounge.status != 'active');

    // 1. Only Lounge Owners who haven't completed setup need Onboarding
    if (!isSuperAdmin && isLoungeOwner && !user.isSetupCompleted) {
      if (!isOnboardingPath) return RouterKeys.loungeOnboarding;
      return null;
    }

    // 2. Lounge Owners whose lounge/KYC is still pending approval go to KYC Pending Screen
    if (!isSuperAdmin &&
        isLoungeOwner &&
        user.isSetupCompleted &&
        isLoungePending) {
      if (!isKycPendingPath) return RouterKeys.kycPending;
      return null;
    }

    // Leave onboarding or kyc-pending if status is active or user is non-owner
    if ((isOnboardingPath || isKycPendingPath) &&
        (user.isSetupCompleted && !isLoungePending)) {
      return RouterKeys.loungeAdminDashboard;
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

    final bool isStaffManagementRoute =
        location == RouterKeys.loungeAdminStaff;
    final bool isFinancialRoute =
        location.contains('/payouts') || location.contains('/reports');
    final bool isShiftHistoryRoute =
        location == RouterKeys.loungeAdminShifts;
    final bool isMarketingRoute = location == RouterKeys.loungeAdminMarketing;
    final bool isSetupRoute = location == RouterKeys.loungeAdminRooms ||
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

    if (isSetupRoute && !user.canEditSetup) {
      return '${RouterKeys.loungeAdminDashboard}?unauthorized=true';
    }

    return null;
  }
}
