import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'dashboard_sidebar.dart';
import 'dashboard_top_bar.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/login/login_cubit.dart';
import '../../features/auth/presentation/login/login_state.dart';
import '../../features/shifts/presentation/shift_management/shift_cubit.dart';
import '../../features/shifts/presentation/shift_management/shift_state.dart';
import '../../features/shifts/presentation/shift_management/widgets/open_shift_dialog.dart';
import '../../features/shifts/presentation/shift_management/widgets/shift_summary_modal.dart';
import '../../features/shifts/presentation/shift_management/widgets/shift_header_banner.dart';
import '../../features/permissions/presentation/cubit/permissions_cubit.dart';
import '../../core/di/di.dart';
import '../widgets/geolocation_handler.dart';

class DashboardShell extends StatelessWidget {
  final Widget child;
  final String location;

  const DashboardShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (prev, curr) => prev.user != curr.user,
      builder: (context, loginState) {
        final user = loginState.user;
        final isSuperAdmin = user?.role == UserRole.superAdmin;
        final isLoungeOwner = user?.role == UserRole.owner;
        
        // Determine the role string for permissions for non-privileged users
        // We use the rawRole from DB to match the Supabase expectations
        String? permissionRole = user?.rawRole;
        if (isSuperAdmin || isLoungeOwner || user?.role == UserRole.manager) {
          permissionRole = null; // These roles bypass granular permissions
        }

        String activeRoute = '';
        String title = AppStrings.dashboard;

        if (location.contains('dashboard')) {
          activeRoute = AppStrings.dashboard;
          title = AppStrings.systemOverview;
        } else if (location.contains('lounges')) {
          activeRoute = AppStrings.lounges;
          title = AppStrings.lounges;
        } else if (location.contains('rooms')) {
          activeRoute = AppStrings.rooms;
          title = AppStrings.manageRoomsDesc;
        } else if (location.contains('live-operations')) {
          activeRoute = AppStrings.bookings;
          title = AppStrings.liveBookingsFeed;
        } else if (location.contains('users')) {
          activeRoute = AppStrings.users;
          title = AppStrings.loungeAdministrators;
        } else if (location.contains('marketing')) {
          activeRoute = AppStrings.marketing;
          title = AppStrings.marketing;
        } else if (location.contains('payouts')) {
          activeRoute = isSuperAdmin ? AppStrings.payouts : AppStrings.myPayouts;
          title = isSuperAdmin ? AppStrings.loungePayouts : AppStrings.payoutHistory;
        } else if (location.contains('kyc')) {
          activeRoute = AppStrings.kycReviews;
          title = AppStrings.kycReviews;
        } else if (location.contains('loyalty')) {
          activeRoute = AppStrings.loyaltyRewards;
          title = AppStrings.loyaltyRewards;
        } else if (location.contains('shifts')) {
          activeRoute = AppStrings.shiftHistory;
          title = AppStrings.shiftHistory;
        } else if (location.contains('staff')) {
          activeRoute = AppStrings.staffManagement;
          title = AppStrings.staffManagement;
        } else if (location.contains('reports')) {
          activeRoute = AppStrings.monthlyReports;
          title = AppStrings.monthlyReports;
        } else if (location.contains('profile')) {
          activeRoute = AppStrings.myProfile;
          title = AppStrings.myProfile;
        }

        return GeolocationHandler(
          child: MultiBlocProvider(
            key: ValueKey(user?.id ?? 'guest'), // Force recreation of providers on user change
            providers: [
              BlocProvider(
                create: (context) {
                  final loungeId = user?.loungeId;
                  debugPrint('DashboardShell: Creating ShiftCubit for lounge: $loungeId');
                  final cubit = sl<ShiftCubit>();
                  if (loungeId != null && loungeId.isNotEmpty) {
                    cubit.checkActiveShift(loungeId);
                  }
                  return cubit;
                },
              ),
              BlocProvider(
                create: (context) {
                  final cubit = sl<PermissionsCubit>();
                  if (permissionRole != null) {
                    cubit.fetchPermissions(permissionRole);
                  }
                  return cubit;
                },
              ),
            ],
            child: BlocListener<ShiftCubit, ShiftState>(
              listenWhen: (prev, curr) {
                debugPrint('DashboardShell: Shift status changed from ${prev.status} to ${curr.status}');
                return prev.status != curr.status;
              },
              listener: (context, state) {
                final isCashier = user?.role == UserRole.cashier;
                debugPrint('DashboardShell: Shift Listener - User: ${user?.email}, Role: ${user?.role}, isCashier: $isCashier, Status: ${state.status}');
                
                if (state.status == ShiftStatus.error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error checking shift status: ${state.errorMessage}'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }

                if (state.status == ShiftStatus.initial && isCashier) {
                   debugPrint('DashboardShell: No active shift found for staff, showing OpenShiftDialog');
                   _showOpenShiftDialog(context, user?.loungeId ?? '');
                } else if (state.status == ShiftStatus.closed && state.lastClosedShift != null) {
                  // Only show summary and logout if the shift belongs to the current user
                  if (state.lastClosedShift!.cashierId == user?.id) {
                    _showShiftSummary(context, state.lastClosedShift!);
                  } else {
                    // It was a force close by an admin or another context
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Shift closed successfully.'), backgroundColor: Colors.green),
                    );
                    // Refresh history or overview if needed
                    context.read<ShiftCubit>().resetToInitial();
                    if (user?.loungeId != null) {
                      context.read<ShiftCubit>().getLiveShiftOverview(user!.loungeId!);
                    }
                  }
                }
              },
              child: Scaffold(
                backgroundColor: AppColors.scaffoldBackground,
                drawer: Responsive.isDesktop(context) 
                    ? null 
                    : Drawer(child: DashboardSidebar(activeRoute: activeRoute)),
                body: Row(
                  children: [
                    if (Responsive.isDesktop(context))
                      DashboardSidebar(activeRoute: activeRoute),
                    Expanded(
                      child: Column(
                        children: [
                          DashboardTopBar(
                            title: title,
                            showMenuButton: !Responsive.isDesktop(context),
                          ),
                          if (!isSuperAdmin) const ShiftHeaderBanner(),
                          Expanded(
                            child: child,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showOpenShiftDialog(BuildContext context, String loungeId) {
    final loginCubit = context.read<LoginCubit>();
    final shiftCubit = context.read<ShiftCubit>();
    final permissionsCubit = context.read<PermissionsCubit>();
    final user = loginCubit.state.user;
    final isDismissible = user?.role != UserRole.cashier;

    showDialog(
      context: context,
      barrierDismissible: isDismissible,
      builder: (diagContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: loginCubit),
          BlocProvider.value(value: shiftCubit),
          BlocProvider.value(value: permissionsCubit),
        ],
        child: OpenShiftDialog(
          isDismissible: isDismissible,
          onConfirm: (startingCash) {
            shiftCubit.openShift(loungeId, startingCash);
            Navigator.pop(diagContext);
          },
        ),
      ),
    );
  }

  void _showShiftSummary(BuildContext context, dynamic shift) {
    final loginCubit = context.read<LoginCubit>();
    final shiftCubit = context.read<ShiftCubit>();
    final permissionsCubit = context.read<PermissionsCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (diagContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: loginCubit),
          BlocProvider.value(value: shiftCubit),
          BlocProvider.value(value: permissionsCubit),
        ],
        child: ShiftSummaryModal(
          shift: shift,
          onFinish: () {
            loginCubit.logout();
            Navigator.pop(diagContext);
          },
        ),
      ),
    ).then((_) {
      shiftCubit.resetToInitial();
    });
  }
}
