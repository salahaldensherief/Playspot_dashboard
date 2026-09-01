import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_screen.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_screen.dart' as dashboard;
import 'package:play_spot_dashboard/features/analytics/presentation/cubit/lounge_stats_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/pages/lounges_page.dart' as lounges;
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/users/presentation/pages/users_page.dart' as users;
import 'package:play_spot_dashboard/features/categories/presentation/categories/categories_screen.dart' as categories;
import 'package:play_spot_dashboard/features/marketing/presentation/pages/marketing_page.dart' as marketing;
import 'package:play_spot_dashboard/features/payouts/presentation/pages/super_admin_payouts_page.dart' as payouts;
import 'package:play_spot_dashboard/features/payouts/presentation/pages/lounge_admin_payouts_page.dart' as lounge_payouts;
import 'package:play_spot_dashboard/features/bookings/presentation/pages/bookings_page.dart' as bookings;
import 'package:play_spot_dashboard/features/rooms/presentation/pages/room_management_page.dart' as rooms;
import 'package:play_spot_dashboard/features/onboarding/presentation/pages/lounge_setup_page.dart' as onboarding;
import 'package:play_spot_dashboard/features/lounges/presentation/pages/extras_management_page.dart' as extras;
import 'package:play_spot_dashboard/features/lounges/presentation/pages/lounge_profile_page.dart' as lounge_profile;
import 'package:play_spot_dashboard/features/auth/presentation/profile/profile_page.dart' as profile;
import 'package:play_spot_dashboard/features/kyc/presentation/pages/kyc_reviews_page.dart' as kyc_reviews;
import 'package:play_spot_dashboard/features/loyalty/presentation/pages/loyalty_page.dart' as loyalty;
import 'package:play_spot_dashboard/features/shifts/presentation/shift_history/shift_history_screen.dart' as shifts;
import 'package:play_spot_dashboard/features/staff/presentation/staff_management/staff_screen.dart' as staff;
import 'package:play_spot_dashboard/features/staff/presentation/staff_management/staff_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/pages/booking_history_page.dart' as reports;
import 'package:play_spot_dashboard/features/splash/presentation/splash_screen.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_shell.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/users/presentation/cubit/admin_management_cubit.dart';
import 'package:play_spot_dashboard/features/categories/presentation/categories/category_cubit.dart';
import 'package:play_spot_dashboard/features/marketing/presentation/cubit/marketing_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/extras_cubit.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/cubit/kyc_cubit.dart';
import 'package:play_spot_dashboard/features/loyalty/presentation/cubit/loyalty_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';

import '../../features/permissions/presentation/cubit/permissions_cubit.dart';

import 'go_router_refresh_stream.dart';

class AppRouter {
  final LoginCubit authCubit;

  AppRouter(this.authCubit);

  late final router = GoRouter(
    initialLocation: RouterKeys.root,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
        final authState = authCubit.state;
        final bool isLoggingIn = state.matchedLocation == RouterKeys.login;
        final user = authState.user;

        if (authState.status == LoginStatus.initial || authState.status == LoginStatus.checking) {
          return null;
        }

        final bool isAuthenticated = authState.status == LoginStatus.authenticated || 
                                     authState.status == LoginStatus.success;

        if (!isAuthenticated) {
          return isLoggingIn ? null : RouterKeys.login;
        }

        if (user == null) return isLoggingIn ? null : null;

        final bool isLoungeAdmin = user.isStaff;
        final bool isSuperAdmin = user.role == UserRole.superAdmin;
        final bool isLoungeOwner = user.isLoungeOwner;
        final bool isOnboardingPath = state.matchedLocation == RouterKeys.loungeOnboarding;

        if (user.isLoungeOwner && !user.isSetupCompleted) {
          if (!isOnboardingPath) return RouterKeys.loungeOnboarding;
          return null;
        }

        if (isOnboardingPath && user.isSetupCompleted) {
          return RouterKeys.loungeAdminDashboard;
        }

        if (isLoggingIn || state.matchedLocation == RouterKeys.root) {
          if (isSuperAdmin) return RouterKeys.superAdminDashboard;
          if (isLoungeAdmin) return RouterKeys.loungeAdminDashboard;
        }

        final String location = state.matchedLocation;

        if (location.startsWith('/super-admin') && !isSuperAdmin) {
          return RouterKeys.loungeAdminDashboard;
        }

        final bool isStaffManagementRoute = location == RouterKeys.loungeAdminStaff;
        final bool isFinancialRoute = location.contains('/payouts') || location.contains('/reports');
        final bool isMarketingRoute = location == RouterKeys.loungeAdminMarketing;
        final bool isSetupRoute = location == RouterKeys.loungeAdminRooms || location == RouterKeys.loungeAdminExtras;

        if (isStaffManagementRoute && !user.canManageStaff) {
          return RouterKeys.loungeAdminDashboard;
        }

        if (isFinancialRoute && !user.canViewFinancials) {
          return RouterKeys.loungeAdminDashboard;
        }

        if (isMarketingRoute && !user.canManageMarketing) {
          return RouterKeys.loungeAdminDashboard;
        }

        if (isSetupRoute && !user.canEditSetup) {
          return RouterKeys.loungeAdminDashboard;
        }

        return null;
      },
      routes: [
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return BlocProvider(
              create: (context) => authCubit,
              child: BlocBuilder<LoginCubit, LoginState>(
                buildWhen: (previous, current) => previous.status != current.status,
                builder: (context, authState) {
                  if (authState.status == LoginStatus.checking) {
                    return const SplashScreen();
                  }
                  return child;
                },
              ),
            );
          },
          routes: [
            GoRoute(
              path: RouterKeys.login,
              pageBuilder: (context, state) => const NoTransitionPage(child: LoginScreen()),
            ),
            GoRoute(
              path: RouterKeys.loungeOnboarding,
              pageBuilder: (context, state) => NoTransitionPage(
                child: BlocProvider(
                  create: (context) => sl<OnboardingCubit>(),
                  child: BlocProvider(
                    create: (context) => sl<CategoryCubit>()..loadCategories(),
                    child: BlocProvider(
                      create: (context) => sl<KycCubit>(),
                      child: const onboarding.LoungeSetupPage(),
                    ),
                  ),
                ),
              ),
            ),
            
            ShellRoute(
              builder: (BuildContext context, GoRouterState state, Widget child) {
                final user = context.read<LoginCubit>().state.user;
                final isSuperAdmin = user?.role == UserRole.superAdmin;
                final isLoungeOwner = user?.role == UserRole.owner;
                
                String? permissionRole = user?.rawRole;
                if (isSuperAdmin || isLoungeOwner || user?.role == UserRole.manager) {
                  permissionRole = null; 
                }

                return BlocProvider(
                  create: (context) => sl<ShiftCubit>(),
                  child: BlocProvider(
                    create: (context) => sl<BookingCubit>(),
                    child: BlocProvider(
                      create: (context) => sl<LoungeCubit>(),
                      child: BlocProvider(
                        create: (context) => sl<RoomCubit>(),
                        child: BlocProvider(
                          create: (context) => sl<LoungeStatsCubit>(),
                          child: BlocProvider(
                            create: (context) => sl<DashboardCubit>(),
                            child: BlocProvider(
                              create: (context) => sl<ExtrasCubit>(),
                              child: BlocProvider(
                                create: (context) {
                                  final cubit = sl<PermissionsCubit>();
                                  if (permissionRole != null) {
                                    cubit.fetchPermissions(permissionRole);
                                  }
                                  return cubit;
                                },
                                child: DashboardShell(
                                  location: state.matchedLocation,
                                  child: child,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              routes: [
                GoRoute(
                  path: RouterKeys.superAdminDashboard,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: dashboard.DashboardScreen(role: UserRole.superAdmin),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.superAdminLounges,
                  pageBuilder: (context, state) => const NoTransitionPage(child: lounges.LoungesPage()),
                ),
                GoRoute(
                  path: RouterKeys.superAdminUsers,
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: BlocProvider(
                      create: (context) => sl<AdminManagementCubit>()..fetchAdmins(),
                      child: const users.UsersPage(),
                    ),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.superAdminCategories,
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: BlocProvider(
                      create: (context) => sl<CategoryCubit>()..loadCategories(),
                      child: const categories.CategoriesScreen(),
                    ),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.superAdminMarketing,
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: BlocProvider(
                      create: (context) => sl<MarketingCubit>()..loadPromotions(),
                      child: const marketing.MarketingPage(),
                    ),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.superAdminPayouts,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: payouts.SuperAdminPayoutsPage(),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.superAdminKyc,
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: BlocProvider(
                      create: (context) => sl<KycCubit>()..loadPendingReviews(),
                      child: const kyc_reviews.KycReviewsPage(),
                    ),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.superAdminLoyalty,
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: BlocProvider(
                      create: (context) => sl<LoyaltyCubit>(),
                      child: const loyalty.LoyaltyPage(),
                    ),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.superAdminShifts,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: shifts.ShiftHistoryScreen(),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.loungeAdminDashboard,
                  pageBuilder: (context, state) {
                    final user = context.read<LoginCubit>().state.user;
                    return NoTransitionPage(
                      child: dashboard.DashboardScreen(role: user?.role ?? UserRole.manager),
                    );
                  },
                ),
                GoRoute(
                  path: RouterKeys.loungeAdminLiveOps,
                  pageBuilder: (context, state) => const NoTransitionPage(child: bookings.BookingsPage()),
                ),
                GoRoute(
                  path: RouterKeys.loungeAdminRooms,
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: BlocProvider(
                      create: (context) => sl<CategoryCubit>()..loadCategories(),
                      child: const rooms.RoomManagementPage(),
                    ),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.loungeAdminExtras,
                  pageBuilder: (context, state) => const NoTransitionPage(child: extras.ExtrasManagementPage()),
                ),
                GoRoute(
                  path: RouterKeys.loungeAdminMarketing,
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: BlocProvider(
                      create: (context) => sl<MarketingCubit>()..loadPromotions(loungeId: context.read<LoginCubit>().state.user?.loungeId),
                      child: const marketing.MarketingPage(),
                    ),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.loungeAdminPayouts,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: lounge_payouts.LoungeAdminPayoutsPage(),
                  ),
                ),
                GoRoute(
                  path: '/lounge-admin/reports',
                  pageBuilder: (context, state) => const NoTransitionPage(child: reports.BookingHistoryPage()),
                ),
                GoRoute(
                  path: '/lounge-admin/shifts',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: shifts.ShiftHistoryScreen(),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.loungeAdminStaff,
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: BlocProvider(
                      create: (context) => sl<StaffCubit>(),
                      child: const staff.StaffScreen(),
                    ),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.loungeAdminProfile,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: lounge_profile.LoungeProfilePage(),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.profile,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: profile.ProfilePage(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(AppStrings.pageNotFound, style: const TextStyle(color: Colors.white, fontSize: 24)),
              const SizedBox(height: 16),
              AppButton(
                onPressed: () => context.go(RouterKeys.root),
                text: AppStrings.goHome,
              ),
            ],
          ),
        ),
      ),
    );
}
