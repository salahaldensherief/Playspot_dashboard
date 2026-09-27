import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/art_core/di/provider_scope.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_screen.dart'
    as dashboard;
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/categories/presentation/categories/categories_screen.dart'
    as categories;
import 'package:play_spot_dashboard/features/categories/presentation/categories/category_cubit.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/cubit/kyc_cubit.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/pages/kyc_reviews_page.dart'
    as kyc_reviews;
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/pages/lounges_page.dart'
    as lounges;
import 'package:play_spot_dashboard/features/loyalty/presentation/cubit/loyalty_cubit.dart';
import 'package:play_spot_dashboard/features/loyalty/presentation/pages/loyalty_page.dart'
    as loyalty;
import 'package:play_spot_dashboard/features/marketing/presentation/cubit/marketing_cubit.dart';
import 'package:play_spot_dashboard/features/marketing/presentation/pages/marketing_page.dart'
    as marketing;
import 'package:play_spot_dashboard/features/payouts/presentation/cubit/payout_cubit.dart';
import 'package:play_spot_dashboard/features/payouts/presentation/pages/super_admin_payouts_page.dart'
    as payouts;
import 'package:play_spot_dashboard/features/support/presentation/faq_management_screen.dart';
import 'package:play_spot_dashboard/features/support/presentation/policy_management_screen.dart';
import 'package:play_spot_dashboard/features/support/presentation/support_cubit.dart';
import 'package:play_spot_dashboard/features/support/presentation/support_settings_screen.dart';
import 'package:play_spot_dashboard/features/support/presentation/support_tickets_screen.dart';
import 'package:play_spot_dashboard/features/system/presentation/system_settings_cubit.dart';
import 'package:play_spot_dashboard/features/system/presentation/system_settings_screen.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_cubit.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_matches_cubit.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_participants_cubit.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournaments_screen.dart'
    as tournaments;
import 'package:play_spot_dashboard/features/users/presentation/cubit/admin_management_cubit.dart';
import 'package:play_spot_dashboard/features/users/presentation/pages/users_page.dart'
    as users;

List<RouteBase> getSuperAdminRoutes() {
  return [
    GoRoute(
      path: RouterKeys.superAdminDashboard,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: dashboard.DashboardScreen(role: UserRole.superAdmin),
      ),
    ),
    GoRoute(
      path: RouterKeys.superAdminLounges,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: lounges.LoungesPage()),
    ),
    GoRoute(
      path: RouterKeys.superAdminUsers,
      pageBuilder: (context, state) => NoTransitionPage(
        child: MultiBlocProviderScope(
          providers: [
            BlocProvider(
              create: (_) => sl<AdminManagementCubit>(),
            ),
            BlocProvider(
              create: (_) => sl<LoungeCubit>(),
            ),
          ],
          child: const users.UsersPage(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.superAdminCategories,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<CategoryCubit>(),
          child: const categories.CategoriesScreen(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.superAdminMarketing,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<MarketingCubit>(),
          child: const marketing.MarketingPage(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.superAdminPayouts,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<PayoutCubit>(),
          child: const payouts.SuperAdminPayoutsPage(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.superAdminKyc,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<KycCubit>(),
          child: const kyc_reviews.KycReviewsPage(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.superAdminLoyalty,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<LoyaltyCubit>(),
          child: const loyalty.LoyaltyPage(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.superAdminTournaments,
      pageBuilder: (context, state) => NoTransitionPage(
        child: MultiBlocProviderScope(
          providers: [
            BlocProvider(create: (_) => sl<TournamentCubit>()),
            BlocProvider(
              create: (_) => sl<TournamentParticipantsCubit>(),
            ),
            BlocProvider(create: (_) => sl<TournamentMatchesCubit>()),
          ],
          child: const tournaments.TournamentsScreen(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.superAdminSupportSettings,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<SupportCubit>(),
          child: const SupportSettingsScreen(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.superAdminPolicies,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<SupportCubit>(),
          child: const PolicyManagementScreen(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.superAdminFaqs,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<SupportCubit>(),
          child: const FaqManagementScreen(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.superAdminTickets,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<SupportCubit>(),
          child: const SupportTicketsScreen(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.superAdminSystemSettings,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<SystemSettingsCubit>(),
          child: const SystemSettingsScreen(),
        ),
      ),
    ),
  ];
}
