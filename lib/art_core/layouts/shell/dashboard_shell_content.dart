import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/new_booking_alert_dialog.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_state.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/open_shift_dialog.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/shift_header_banner.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/shift_summary_modal.dart';
import '../dashboard_sidebar.dart';
import '../dashboard_top_bar.dart';

class DashboardShellContent extends StatefulWidget {
  final String location;
  final String activeRoute;
  final String title;
  final UserEntity? user;
  final bool isSuperAdmin;
  final Widget child;

  const DashboardShellContent({
    super.key,
    required this.location,
    required this.activeRoute,
    required this.title,
    required this.user,
    required this.isSuperAdmin,
    required this.child,
  });

  @override
  State<DashboardShellContent> createState() => _DashboardShellContentState();
}

class _DashboardShellContentState extends State<DashboardShellContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUnauthorizedNotice();
      _initializePermissionsAndLounges();
      final loungeId = widget.user?.loungeId;
      if (loungeId != null && loungeId.isNotEmpty) {
        context.read<ShiftCubit>().checkActiveShift(loungeId);
        context.read<BookingCubit>().startWatchingBookings(loungeId: loungeId);
        context
            .read<ClientRequestsCubit>()
            .startWatchingRequests(loungeId: loungeId);
      } else if (widget.isSuperAdmin) {
        context.read<BookingCubit>().startWatchingBookings();
      }
    });
  }

  void _initializePermissionsAndLounges() {
    final loginState = context.read<LoginCubit>().state;
    final user = loginState.user;
    final loungeId = user?.loungeId ?? loginState.userLounge?.id;
    final roleStr = user?.rawRole ?? user?.role.name ?? 'staff';
    context
        .read<PermissionsCubit>()
        .loadUserPermissions(roleStr, loungeId: loungeId);

    final loungeCubit = context.read<LoungeCubit>();
    loungeCubit.initSelectedLounge(loungeId);
    if (loungeCubit.state.status == LoungeStatus.initial) {
      loungeCubit.fetchLounges();
    }
  }

  @override
  void didUpdateWidget(covariant DashboardShellContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != oldWidget.location) {
      _checkUnauthorizedNotice();
    }
    if (widget.user?.id != oldWidget.user?.id ||
        widget.user?.role != oldWidget.user?.role ||
        widget.user?.loungeId != oldWidget.user?.loungeId) {
      _initializePermissionsAndLounges();
    }
    if (widget.user?.loungeId != oldWidget.user?.loungeId) {
      final loungeId = widget.user?.loungeId;
      if (loungeId != null && loungeId.isNotEmpty) {
        context.read<BookingCubit>().startWatchingBookings(loungeId: loungeId);
        context
            .read<ClientRequestsCubit>()
            .startWatchingRequests(loungeId: loungeId);
      } else if (widget.isSuperAdmin) {
        context.read<BookingCubit>().startWatchingBookings();
      }
    }
  }

  void _checkUnauthorizedNotice() {
    if (widget.location.contains('unauthorized=true')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.unauthorizedAccessMsg,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ShiftCubit, ShiftState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            final isCashier = widget.user?.role == UserRole.cashier;

            if (state.status == ShiftStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      AppStrings.errorCheckingShift(state.errorMessage ?? '')),
                  backgroundColor: AppColors.danger,
                ),
              );
            }

            if (state.status == ShiftStatus.initial && isCashier) {
              _showOpenShiftDialog(context, widget.user?.loungeId ?? '');
            } else if (state.status == ShiftStatus.closed &&
                state.lastClosedShift != null) {
              final lastShift = state.lastClosedShift;
              if (lastShift?.cashierId == widget.user?.id) {
                _showShiftSummary(context, lastShift);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(AppStrings.shiftClosedSuccess),
                      backgroundColor: AppColors.success),
                );
                context.read<ShiftCubit>().resetToInitial();
                final currentLoungeId = widget.user?.loungeId;
                if (currentLoungeId != null && currentLoungeId.isNotEmpty) {
                  context
                      .read<ShiftCubit>()
                      .getLiveShiftOverview(currentLoungeId);
                }
              }
            }
          },
        ),
        BlocListener<BookingCubit, BookingState>(
          listenWhen: (prev, curr) =>
              curr.latestNewBooking != null &&
              curr.latestNewBooking != prev.latestNewBooking,
          listener: (context, state) {
            final newBooking = state.latestNewBooking;
            final bookingCubit = context.read<BookingCubit>();
            if (newBooking != null) {
              showDialog(
                context: context,
                useRootNavigator: false,
                builder: (diagContext) => BlocProvider.value(
                  value: bookingCubit,
                  child: NewBookingAlertDialog(booking: newBooking),
                ),
              ).then((_) {
                if (context.mounted) {
                  bookingCubit.clearLatestNewBooking();
                }
              });
            }
          },
        ),
        BlocListener<LoungeCubit, LoungeState>(
          listenWhen: (prev, curr) =>
              curr.selectedLoungeId != null &&
              prev.selectedLoungeId != curr.selectedLoungeId,
          listener: (context, state) {
            final activeId = state.selectedLoungeId;
            if (activeId != null && activeId.isNotEmpty) {
              context.read<ShiftCubit>().checkActiveShift(activeId);
              context
                  .read<BookingCubit>()
                  .startWatchingBookings(loungeId: activeId);
              context
                  .read<ClientRequestsCubit>()
                  .startWatchingRequests(loungeId: activeId);
              final roleStr =
                  widget.user?.rawRole ?? widget.user?.role.name ?? 'staff';
              context
                  .read<PermissionsCubit>()
                  .loadUserPermissions(roleStr, loungeId: activeId);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        drawer: Responsive.isMobile(context)
            ? Drawer(child: DashboardSidebar(activeRoute: widget.activeRoute))
            : null,
        body: Row(
          children: [
            if (!Responsive.isMobile(context))
              DashboardSidebar(activeRoute: widget.activeRoute),
            Expanded(
              child: Column(
                children: [
                  DashboardTopBar(
                    title: widget.title,
                    showMenuButton: Responsive.isMobile(context),
                    actions: widget.activeRoute == RouterKeys.profile
                        ? [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.textPrimary),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text(AppStrings.underConstruction)),
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
