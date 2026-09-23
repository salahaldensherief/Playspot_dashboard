import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';

class ShellRouteInfo {
  final String activeRoute;
  final String title;

  const ShellRouteInfo({required this.activeRoute, required this.title});
}

class ShellRouteResolver {
  static ShellRouteInfo resolve({
    required String location,
    required bool isSuperAdmin,
  }) {
    if (isSuperAdmin) {
      if (location.startsWith(RouterKeys.superAdminDashboard)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.superAdminDashboard,
            title: AppStrings.systemOverview);
      } else if (location.startsWith(RouterKeys.superAdminLounges)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.superAdminLounges,
            title: AppStrings.lounges);
      } else if (location.startsWith(RouterKeys.superAdminPayouts)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.superAdminPayouts,
            title: AppStrings.loungePayouts);
      } else if (location.startsWith(RouterKeys.superAdminKyc)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.superAdminKyc,
            title: AppStrings.kycReviews);
      } else if (location.startsWith(RouterKeys.superAdminLoyalty)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.superAdminLoyalty,
            title: AppStrings.loyaltySystemAndReferrals);
      } else if (location.startsWith(RouterKeys.superAdminTournaments)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.superAdminTournaments,
            title: AppStrings.tournaments);
      } else if (location.startsWith(RouterKeys.superAdminSupportSettings)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.superAdminSupportSettings,
            title: AppStrings.supportAndPaymentSettings);
      } else if (location.startsWith(RouterKeys.superAdminPolicies)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.superAdminPolicies,
            title: AppStrings.policiesManagement);
      } else if (location.startsWith(RouterKeys.superAdminFaqs)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.superAdminFaqs,
            title: AppStrings.faqsTitle);
      } else if (location.startsWith(RouterKeys.superAdminTickets)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.superAdminTickets,
            title: AppStrings.supportTickets);
      } else if (location.startsWith(RouterKeys.superAdminSystemSettings)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.superAdminSystemSettings,
            title: AppStrings.systemAndAnnouncements);
      } else if (location.startsWith(RouterKeys.superAdminCategories)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.superAdminCategories,
            title: AppStrings.categories);
      } else if (location.startsWith(RouterKeys.superAdminMarketing)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.superAdminMarketing,
            title: AppStrings.marketing);
      } else if (location.startsWith(RouterKeys.superAdminUsers)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.superAdminUsers,
            title: AppStrings.loungeAdministrators);
      } else if (location.startsWith(RouterKeys.profile)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.profile,
            title: AppStrings.myProfile);
      }
      return ShellRouteInfo(
          activeRoute: RouterKeys.superAdminDashboard,
          title: AppStrings.dashboard);
    } else {
      if (location.startsWith(RouterKeys.loungeAdminDashboard)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.loungeAdminDashboard,
            title: AppStrings.dashboard);
      } else if (location.startsWith(RouterKeys.loungeAdminLiveOps)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.loungeAdminLiveOps,
            title: AppStrings.bookings);
      } else if (location.startsWith(RouterKeys.loungeAdminRooms)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.loungeAdminRooms,
            title: AppStrings.manageRoomsDesc);
      } else if (location.startsWith(RouterKeys.loungeAdminExtras)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.loungeAdminExtras,
            title: AppStrings.extras);
      } else if (location.startsWith(RouterKeys.loungeAdminReviews)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.loungeAdminReviews,
            title: AppStrings.loungeReviews);
      } else if (location.startsWith(RouterKeys.loungeAdminMarketing)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.loungeAdminMarketing,
            title: AppStrings.marketing);
      } else if (location.startsWith(RouterKeys.loungeAdminTournaments)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.loungeAdminTournaments,
            title: AppStrings.tournaments);
      } else if (location.startsWith(RouterKeys.loungeAdminStaff)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.loungeAdminStaff,
            title: AppStrings.staffManagement);
      } else if (location.startsWith(RouterKeys.loungeAdminShifts)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.loungeAdminShifts,
            title: AppStrings.shiftHistory);
      } else if (location.startsWith(RouterKeys.loungeAdminReports)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.loungeAdminReports,
            title: AppStrings.monthlyReports);
      } else if (location.startsWith(RouterKeys.loungeAdminPayouts)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.loungeAdminPayouts,
            title: AppStrings.myPayouts);
      } else if (location.startsWith(RouterKeys.loungeAdminProfile)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.loungeAdminProfile,
            title: AppStrings.loungeProfile);
      } else if (location.startsWith(RouterKeys.loungeAdminSupport)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.loungeAdminSupport,
            title: AppStrings.supportAndHelp);
      } else if (location.startsWith(RouterKeys.profile)) {
        return ShellRouteInfo(
            activeRoute: RouterKeys.profile,
            title: AppStrings.myProfile);
      }
      return ShellRouteInfo(
          activeRoute: RouterKeys.loungeAdminDashboard,
          title: AppStrings.dashboard);
    }
  }
}
