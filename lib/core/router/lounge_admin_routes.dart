import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/art_core/di/provider_scope.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_screen.dart'
    as dashboard;
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/profile/profile_page.dart'
    as profile;
import 'package:play_spot_dashboard/features/bookings/presentation/pages/booking_history_page.dart'
    as reports;
import 'package:play_spot_dashboard/features/bookings/presentation/pages/bookings_page.dart'
    as bookings;
import 'package:play_spot_dashboard/features/categories/presentation/categories/category_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/pages/extras_management_page.dart'
    as extras;
import 'package:play_spot_dashboard/features/lounges/presentation/pages/lounge_profile_page.dart'
    as lounge_profile;
import 'package:play_spot_dashboard/features/marketing/presentation/cubit/marketing_cubit.dart';
import 'package:play_spot_dashboard/features/marketing/presentation/pages/marketing_page.dart'
    as marketing;
import 'package:play_spot_dashboard/features/payouts/presentation/cubit/payout_cubit.dart';
import 'package:play_spot_dashboard/features/payouts/presentation/pages/lounge_admin_payouts_page.dart'
    as lounge_payouts;
import 'package:play_spot_dashboard/features/reviews/presentation/reviews_screen.dart'
    as reviews_page;
import 'package:play_spot_dashboard/features/rooms/presentation/pages/room_management_page.dart'
    as rooms;
import 'package:play_spot_dashboard/features/shifts/presentation/shift_history/shift_history_screen.dart'
    as shifts;
import 'package:play_spot_dashboard/features/staff/presentation/staff_management/staff_cubit.dart';
import 'package:play_spot_dashboard/features/staff/presentation/staff_management/staff_screen.dart'
    as staff;
import 'package:play_spot_dashboard/features/support/presentation/lounge_owner_support_screen.dart';
import 'package:play_spot_dashboard/features/support/presentation/support_cubit.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_cubit.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_matches_cubit.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_participants_cubit.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournaments_screen.dart'
    as tournaments;

List<RouteBase> getLoungeAdminRoutes(LoginCubit authCubit) {
  return [
    GoRoute(
      path: RouterKeys.loungeAdminDashboard,
      pageBuilder: (context, state) {
        final user = authCubit.state.user;
        return NoTransitionPage(
          child: dashboard.DashboardScreen(
            role: user?.role ?? UserRole.manager,
          ),
        );
      },
    ),
    GoRoute(
      path: RouterKeys.loungeAdminLiveOps,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: bookings.BookingsPage()),
    ),
    GoRoute(
      path: RouterKeys.loungeAdminRooms,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<CategoryCubit>(),
          child: const rooms.RoomManagementPage(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.loungeAdminExtras,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: extras.ExtrasManagementPage(),
      ),
    ),
    GoRoute(
      path: RouterKeys.loungeAdminReviews,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: reviews_page.ReviewsScreen(),
      ),
    ),
    GoRoute(
      path: RouterKeys.loungeAdminTournaments,
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
      path: RouterKeys.loungeAdminMarketing,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<MarketingCubit>(),
          child: const marketing.MarketingPage(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.loungeAdminPayouts,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<PayoutCubit>(),
          child: const lounge_payouts.LoungeAdminPayoutsPage(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.loungeAdminReports,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: reports.BookingHistoryPage()),
    ),
    GoRoute(
      path: RouterKeys.loungeAdminShifts,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: shifts.ShiftHistoryScreen()),
    ),
    GoRoute(
      path: RouterKeys.loungeAdminStaff,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<StaffCubit>(),
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
      path: RouterKeys.loungeAdminSupport,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider(
          create: (_) => sl<SupportCubit>(),
          child: const LoungeOwnerSupportScreen(),
        ),
      ),
    ),
    GoRoute(
      path: RouterKeys.profile,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: profile.ProfilePage()),
    ),
  ];
}
