import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/login/login_cubit.dart';
import '../../features/auth/presentation/login/login_state.dart';
import '../../features/bookings/presentation/cubit/booking_cubit.dart';
import '../../features/bookings/presentation/cubit/booking_state.dart';
import '../../features/bookings/presentation/widgets/new_booking_alert_dialog.dart';
import '../../features/requests/presentation/client_requests_cubit.dart';
import '../../features/lounges/presentation/cubit/lounge_cubit.dart';
import '../../features/lounges/presentation/cubit/lounge_state.dart';
import '../../features/shifts/presentation/shift_management/shift_cubit.dart';
import '../../features/shifts/presentation/shift_management/shift_state.dart';
import '../../features/shifts/presentation/shift_management/widgets/open_shift_dialog.dart';
import '../../features/shifts/presentation/shift_management/widgets/shift_summary_modal.dart';
import '../../features/shifts/presentation/shift_management/widgets/shift_header_banner.dart';
import '../../features/permissions/presentation/cubit/permissions_cubit.dart';
import '../../core/router/router_keys.dart';
import 'dashboard_sidebar.dart';
import 'dashboard_top_bar.dart';
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

        if (isSuperAdmin) {
          if (location.startsWith(RouterKeys.superAdminDashboard)) {
            activeRoute = RouterKeys.superAdminDashboard;
            title = AppStrings.systemOverview;
          } else if (location.startsWith(RouterKeys.superAdminLounges)) {
            activeRoute = RouterKeys.superAdminLounges;
            title = AppStrings.lounges;
          } else if (location.startsWith(RouterKeys.superAdminPayouts)) {
            activeRoute = RouterKeys.superAdminPayouts;
            title = AppStrings.loungePayouts;
          } else if (location.startsWith(RouterKeys.superAdminKyc)) {
            activeRoute = RouterKeys.superAdminKyc;
            title = AppStrings.kycReviews;
          } else if (location.startsWith(RouterKeys.superAdminLoyalty)) {
            activeRoute = RouterKeys.superAdminLoyalty;
            title = AppStrings.loyaltySystemAndReferrals;
          } else if (location.startsWith(RouterKeys.superAdminTournaments)) {
            activeRoute = RouterKeys.superAdminTournaments;
            title = AppStrings.tournaments;
          } else if (location.startsWith(RouterKeys.superAdminSupportSettings)) {
            activeRoute = RouterKeys.superAdminSupportSettings;
            title = AppStrings.supportAndPaymentSettings;
          } else if (location.startsWith(RouterKeys.superAdminPolicies)) {
            activeRoute = RouterKeys.superAdminPolicies;
            title = AppStrings.policiesManagement;
          } else if (location.startsWith(RouterKeys.superAdminFaqs)) {
            activeRoute = RouterKeys.superAdminFaqs;
            title = AppStrings.faqsTitle;
          } else if (location.startsWith(RouterKeys.superAdminTickets)) {
            activeRoute = RouterKeys.superAdminTickets;
            title = AppStrings.supportTickets;
          } else if (location.startsWith(RouterKeys.superAdminSystemSettings)) {
            activeRoute = RouterKeys.superAdminSystemSettings;
            title = AppStrings.systemAndAnnouncements;
          } else if (location.startsWith(RouterKeys.superAdminCategories)) {
            activeRoute = RouterKeys.superAdminCategories;
            title = AppStrings.categories;
          } else if (location.startsWith(RouterKeys.superAdminMarketing)) {
            activeRoute = RouterKeys.superAdminMarketing;
            title = AppStrings.marketing;
          } else if (location.startsWith(RouterKeys.superAdminUsers)) {
            activeRoute = RouterKeys.superAdminUsers;
            title = AppStrings.loungeAdministrators;
          } else if (location.startsWith(RouterKeys.profile)) {
            activeRoute = RouterKeys.profile;
            title = AppStrings.myProfile;
          }
        } else {
          if (location.startsWith(RouterKeys.loungeAdminDashboard)) {
            activeRoute = RouterKeys.loungeAdminDashboard;
            title = AppStrings.dashboard;
          } else if (location.startsWith(RouterKeys.loungeAdminLiveOps)) {
            activeRoute = RouterKeys.loungeAdminLiveOps;
            title = AppStrings.bookings;
          } else if (location.startsWith(RouterKeys.loungeAdminRooms)) {
            activeRoute = RouterKeys.loungeAdminRooms;
            title = AppStrings.manageRoomsDesc;
          } else if (location.startsWith(RouterKeys.loungeAdminExtras)) {
            activeRoute = RouterKeys.loungeAdminExtras;
            title = AppStrings.extras;
          } else if (location.startsWith(RouterKeys.loungeAdminReviews)) {
            activeRoute = RouterKeys.loungeAdminReviews;
            title = AppStrings.loungeReviews;
          } else if (location.startsWith(RouterKeys.loungeAdminMarketing)) {
            activeRoute = RouterKeys.loungeAdminMarketing;
            title = AppStrings.marketing;
          } else if (location.startsWith(RouterKeys.loungeAdminTournaments)) {
            activeRoute = RouterKeys.loungeAdminTournaments;
            title = AppStrings.tournaments;
          } else if (location.startsWith(RouterKeys.loungeAdminStaff)) {
            activeRoute = RouterKeys.loungeAdminStaff;
            title = AppStrings.staffManagement;
          } else if (location.startsWith(RouterKeys.loungeAdminShifts)) {
            activeRoute = RouterKeys.loungeAdminShifts;
            title = AppStrings.shiftHistory;
          } else if (location.startsWith(RouterKeys.loungeAdminReports)) {
            activeRoute = RouterKeys.loungeAdminReports;
            title = AppStrings.monthlyReports;
          } else if (location.startsWith(RouterKeys.loungeAdminPayouts)) {
            activeRoute = RouterKeys.loungeAdminPayouts;
            title = AppStrings.myPayouts;
          } else if (location.startsWith(RouterKeys.loungeAdminProfile)) {
            activeRoute = RouterKeys.loungeAdminProfile;
            title = AppStrings.loungeProfile;
          } else if (location.startsWith(RouterKeys.loungeAdminSupport)) {
            activeRoute = RouterKeys.loungeAdminSupport;
            title = AppStrings.supportAndHelp;
          } else if (location.startsWith(RouterKeys.profile)) {
            activeRoute = RouterKeys.profile;
            title = AppStrings.myProfile;
          }
        }

        return GeolocationHandler(
          child: _DashboardShellContent(
            location: location,
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
  final String location;
  final String activeRoute;
  final String title;
  final UserEntity? user;
  final bool isSuperAdmin;
  final Widget child;

  const _DashboardShellContent({
    required this.location,
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
      _checkUnauthorizedNotice();
      _initializePermissionsAndLounges();
      final loungeId = widget.user?.loungeId;
      if (loungeId != null && loungeId.isNotEmpty) {
        context.read<ShiftCubit>().checkActiveShift(loungeId);
        context.read<BookingCubit>().startWatchingBookings(loungeId: loungeId);
        context.read<ClientRequestsCubit>().startWatchingRequests(loungeId: loungeId);
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
    context.read<PermissionsCubit>().loadUserPermissions(roleStr, loungeId: loungeId);

    final loungeCubit = context.read<LoungeCubit>();
    if (loungeCubit.state.status == LoungeStatus.initial) {
      loungeCubit.fetchLounges();
    }
  }

  @override
  void didUpdateWidget(covariant _DashboardShellContent oldWidget) {
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
        context.read<ClientRequestsCubit>().startWatchingRequests(loungeId: loungeId);
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  content: Text(AppStrings.errorCheckingShift(state.errorMessage ?? '')),
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
                  SnackBar(content: Text(AppStrings.shiftClosedSuccess), backgroundColor: Colors.green),
                );
                context.read<ShiftCubit>().resetToInitial();
                if (widget.user?.loungeId != null) {
                  context.read<ShiftCubit>().getLiveShiftOverview(widget.user!.loungeId!);
                }
              }
            }
          },
        ),
        BlocListener<BookingCubit, BookingState>(
          listenWhen: (prev, curr) => curr.latestNewBooking != null && curr.latestNewBooking != prev.latestNewBooking,
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
