import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../features/analytics/presentation/lounge_stats_cubit.dart';
import '../../features/analytics/presentation/dashboard_cubit.dart';
import '../../features/bookings/presentation/cubit/booking_cubit.dart';
import '../../features/lounges/presentation/cubit/extras_cubit.dart';
import '../../features/lounges/presentation/cubit/lounge_cubit.dart';
import '../../features/rooms/presentation/cubit/room_cubit.dart';
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
        } else if (location.contains('lounge-admin/profile')) {
          activeRoute = AppStrings.loungeProfile;
          title = AppStrings.loungeProfile;
        } else if (location.contains('profile')) {
          activeRoute = AppStrings.myProfile;
          title = AppStrings.myProfile;
        }

        return GeolocationHandler(
          child: _DashboardShellContent(
            activeRoute: activeRoute,
            title: title,
            user: user,
            isSuperAdmin: isSuperAdmin,
            child: child,
          ),
        );
      },
    );
  }
}

class _DashboardShellContent extends StatefulWidget {
  final String activeRoute;
  final String title;
  final UserEntity? user;
  final bool isSuperAdmin;
  final Widget child;

  const _DashboardShellContent({
    required this.activeRoute,
    required this.title,
    required this.user,
    required this.isSuperAdmin,
    required this.child,
  });

  @override
  State<_DashboardShellContent> createState() => _DashboardShellContentState();
}

class _DashboardShellContentState extends State<_DashboardShellContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loungeId = widget.user?.loungeId;
      if (loungeId != null && loungeId.isNotEmpty) {
        context.read<ShiftCubit>().checkActiveShift(loungeId);
        context.read<BookingCubit>().startWatchingBookings(loungeId: loungeId);
      } else if (widget.isSuperAdmin) {
        context.read<BookingCubit>().startWatchingBookings();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _DashboardShellContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user?.loungeId != oldWidget.user?.loungeId) {
      final loungeId = widget.user?.loungeId;
      if (loungeId != null && loungeId.isNotEmpty) {
        context.read<BookingCubit>().startWatchingBookings(loungeId: loungeId);
      } else if (widget.isSuperAdmin) {
        context.read<BookingCubit>().startWatchingBookings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ShiftCubit, ShiftState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        final isCashier = widget.user?.role == UserRole.cashier;
        
        if (state.status == ShiftStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error checking shift status: ${state.errorMessage}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }

        if (state.status == ShiftStatus.initial && isCashier) {
           _showOpenShiftDialog(context, widget.user?.loungeId ?? '');
        } else if (state.status == ShiftStatus.closed && state.lastClosedShift != null) {
          if (state.lastClosedShift!.cashierId == widget.user?.id) {
            _showShiftSummary(context, state.lastClosedShift!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Shift closed successfully.'), backgroundColor: Colors.green),
            );
            context.read<ShiftCubit>().resetToInitial();
            if (widget.user?.loungeId != null) {
              context.read<ShiftCubit>().getLiveShiftOverview(widget.user!.loungeId!);
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        drawer: Responsive.isDesktop(context) 
            ? null 
            : Drawer(child: DashboardSidebar(activeRoute: widget.activeRoute)),
        body: Row(
          children: [
            if (Responsive.isDesktop(context))
              DashboardSidebar(activeRoute: widget.activeRoute),
            Expanded(
              child: Column(
                children: [
                  DashboardTopBar(
                    title: widget.title,
                    showMenuButton: !Responsive.isDesktop(context),
                    actions: widget.activeRoute == AppStrings.myProfile 
                      ? [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppStrings.underConstruction)),
                              );
                            },
                          ),
                        ]
                      : null,
                  ),
                  if (!widget.isSuperAdmin) const ShiftHeaderBanner(),
                  Expanded(
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOpenShiftDialog(BuildContext context, String loungeId) {
    final shiftCubit = context.read<ShiftCubit>();
    final isDismissible = widget.user?.role != UserRole.cashier;

    showDialog(
      context: context,
      useRootNavigator: false,
      barrierDismissible: isDismissible,
      builder: (diagContext) => OpenShiftDialog(
        isDismissible: isDismissible,
        onConfirm: (startingCash) {
          shiftCubit.openShift(loungeId, startingCash);
          Navigator.pop(diagContext);
        },
      ),
    );
  }

  void _showShiftSummary(BuildContext context, dynamic shift) {
    final loginCubit = context.read<LoginCubit>();
    final shiftCubit = context.read<ShiftCubit>();

    showDialog(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (diagContext) => ShiftSummaryModal(
        shift: shift,
        onFinish: () {
          loginCubit.logout();
          Navigator.pop(diagContext);
        },
      ),
    ).then((_) {
      shiftCubit.resetToInitial();
    });
  }
}
