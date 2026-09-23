import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/core/utils/permission_extension.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'sidebar_item.dart';

class SidebarNavigationItems extends StatelessWidget {
  final bool isSuperAdmin;
  final UserEntity? user;
  final String activeRoute;

  const SidebarNavigationItems({
    super.key,
    required this.isSuperAdmin,
    required this.user,
    required this.activeRoute,
  });

  List<Widget> _buildSuperAdminItems(BuildContext context) {
    return [
      SidebarItem(
        icon: Icons.analytics_outlined,
        label: AppStrings.analytics,
        isActive: activeRoute == RouterKeys.superAdminDashboard,
        onTap: () => context.go(RouterKeys.superAdminDashboard),
      ),
      SidebarItem(
        icon: Icons.business_outlined,
        label: AppStrings.lounges,
        isActive: activeRoute == RouterKeys.superAdminLounges,
        onTap: () => context.go(RouterKeys.superAdminLounges),
      ),
      SidebarItem(
        icon: Icons.account_balance_wallet_outlined,
        label: AppStrings.payouts,
        isActive: activeRoute == RouterKeys.superAdminPayouts,
        onTap: () => context.go(RouterKeys.superAdminPayouts),
      ),
      SidebarItem(
        icon: Icons.verified_user_outlined,
        label: AppStrings.kycReviews,
        isActive: activeRoute == RouterKeys.superAdminKyc,
        onTap: () => context.go(RouterKeys.superAdminKyc),
      ),
      SidebarItem(
        icon: Icons.card_giftcard_outlined,
        label: AppStrings.loyaltySystemAndReferrals,
        isActive: activeRoute == RouterKeys.superAdminLoyalty,
        onTap: () => context.go(RouterKeys.superAdminLoyalty),
      ),
      SidebarItem(
        icon: Icons.emoji_events_outlined,
        label: AppStrings.tournaments,
        isActive: activeRoute == RouterKeys.superAdminTournaments,
        onTap: () => context.go(RouterKeys.superAdminTournaments),
      ),
      SidebarItem(
        icon: Icons.contact_support_outlined,
        label: AppStrings.supportAndPaymentSettings,
        isActive: activeRoute == RouterKeys.superAdminSupportSettings,
        onTap: () => context.go(RouterKeys.superAdminSupportSettings),
      ),
      SidebarItem(
        icon: Icons.gavel_outlined,
        label: AppStrings.policiesManagement,
        isActive: activeRoute == RouterKeys.superAdminPolicies,
        onTap: () => context.go(RouterKeys.superAdminPolicies),
      ),
      SidebarItem(
        icon: Icons.quiz_outlined,
        label: AppStrings.faqsTitle,
        isActive: activeRoute == RouterKeys.superAdminFaqs,
        onTap: () => context.go(RouterKeys.superAdminFaqs),
      ),
      SidebarItem(
        icon: Icons.confirmation_number_outlined,
        label: AppStrings.supportTickets,
        isActive: activeRoute == RouterKeys.superAdminTickets,
        onTap: () => context.go(RouterKeys.superAdminTickets),
      ),
      SidebarItem(
        icon: Icons.settings_suggest_outlined,
        label: AppStrings.systemAndAnnouncements,
        isActive: activeRoute == RouterKeys.superAdminSystemSettings,
        onTap: () => context.go(RouterKeys.superAdminSystemSettings),
      ),
    ];
  }

  List<Widget> _buildLoungeStaffItems(BuildContext context, UserEntity? user) {
    if (user == null) return [];

    final canViewBookings = context.hasPermission('bookings_view') ||
        context.hasPermission('pos_view_menu');
    final canViewRooms = context.hasPermission('rooms_view');
    final canViewExtras = context.hasPermission('menu_view');
    final canViewReviews = context.hasPermission('reviews_view');
    final canManageMarketing = context.hasPermission('marketing_manage');
    final canViewTournaments = context.hasPermission('tournaments_view') ||
        user.isOwner ||
        user.isManager;
    final canManageStaff = context.hasPermission('staff_management');
    final canViewShiftHistory = context.hasPermission('shifts_view');
    final canViewReports = context.hasPermission('reports_view');
    final canEditLoungeProfile = context.hasPermission('lounge_profile_edit');

    return [
      SidebarItem(
        icon: Icons.analytics_outlined,
        label: AppStrings.dashboard,
        isActive: activeRoute == RouterKeys.loungeAdminDashboard,
        onTap: () => context.go(RouterKeys.loungeAdminDashboard),
      ),
      if (canViewBookings)
        SidebarItem(
          icon: Icons.sensors,
          label: AppStrings.bookings,
          isActive: activeRoute == RouterKeys.loungeAdminLiveOps,
          onTap: () => context.go(RouterKeys.loungeAdminLiveOps),
        ),
      if (canViewRooms)
        SidebarItem(
          icon: Icons.meeting_room_outlined,
          label: AppStrings.rooms,
          isActive: activeRoute == RouterKeys.loungeAdminRooms,
          onTap: () => context.go(RouterKeys.loungeAdminRooms),
        ),
      if (canViewExtras)
        SidebarItem(
          icon: Icons.restaurant_menu,
          label: AppStrings.extras,
          isActive: activeRoute == RouterKeys.loungeAdminExtras,
          onTap: () => context.go(RouterKeys.loungeAdminExtras),
        ),
      if (canViewReviews)
        SidebarItem(
          icon: Icons.star_outline_rounded,
          label: AppStrings.loungeReviews,
          isActive: activeRoute == RouterKeys.loungeAdminReviews,
          onTap: () => context.go(RouterKeys.loungeAdminReviews),
        ),
      if (canManageMarketing)
        SidebarItem(
          icon: Icons.campaign_outlined,
          label: AppStrings.marketing,
          isActive: activeRoute == RouterKeys.loungeAdminMarketing,
          onTap: () => context.go(RouterKeys.loungeAdminMarketing),
        ),
      if (canViewTournaments)
        SidebarItem(
          icon: Icons.emoji_events_outlined,
          label: AppStrings.tournaments,
          isActive: activeRoute == RouterKeys.loungeAdminTournaments,
          onTap: () => context.go(RouterKeys.loungeAdminTournaments),
        ),
      if (canManageStaff)
        SidebarItem(
          icon: Icons.people_outline,
          label: AppStrings.staffManagement,
          isActive: activeRoute == RouterKeys.loungeAdminStaff,
          onTap: () => context.go(RouterKeys.loungeAdminStaff),
        ),
      if (canViewShiftHistory)
        SidebarItem(
          icon: Icons.history_outlined,
          label: AppStrings.shiftHistory,
          isActive: activeRoute == RouterKeys.loungeAdminShifts,
          onTap: () => context.go(RouterKeys.loungeAdminShifts),
        ),
      if (canViewReports)
        SidebarItem(
          icon: Icons.assessment_outlined,
          label: AppStrings.monthlyReports,
          isActive: activeRoute == RouterKeys.loungeAdminReports,
          onTap: () => context.go(RouterKeys.loungeAdminReports),
        ),
      if (canEditLoungeProfile)
        SidebarItem(
          icon: Icons.settings_outlined,
          label: AppStrings.loungeProfile,
          isActive: activeRoute == RouterKeys.loungeAdminProfile,
          onTap: () => context.go(RouterKeys.loungeAdminProfile),
        ),
      SidebarItem(
        icon: Icons.headset_mic_outlined,
        label: AppStrings.supportAndHelp,
        isActive: activeRoute == RouterKeys.loungeAdminSupport,
        onTap: () => context.go(RouterKeys.loungeAdminSupport),
      ),
      SidebarItem(
        icon: Icons.person_outline,
        label: AppStrings.myProfile,
        isActive: activeRoute == RouterKeys.profile,
        onTap: () => context.go(RouterKeys.profile),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: isSuperAdmin
          ? _buildSuperAdminItems(context)
          : _buildLoungeStaffItems(context, user),
    );
  }
}
