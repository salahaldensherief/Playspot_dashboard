import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_card.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_details_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/live_session_card.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_occupancy_grid.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/live_requests_feed.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _lastInitializedLoungeId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<LoginCubit>().state.user;
      final loungeId = user?.loungeId;
      _initRealtimeStreams(loungeId);
    });
  }

  void _initRealtimeStreams(String? loungeId) {
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;

    if (_isInitialized && _lastInitializedLoungeId == cleanLoungeId) {
      return;
    }
    _isInitialized = true;
    _lastInitializedLoungeId = cleanLoungeId;

    context.read<BookingCubit>().startWatchingBookings(loungeId: cleanLoungeId);
    if (cleanLoungeId != null) {
      context.read<ClientRequestsCubit>().startWatchingRequests(loungeId: cleanLoungeId);
      context.read<RoomCubit>().watchRooms(cleanLoungeId);
    }
    context.read<LoungeCubit>().fetchLounges();
  }

  Future<void> _handleRefresh() async {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId;
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;

    context.read<BookingCubit>().startWatchingBookings(loungeId: cleanLoungeId);
    if (cleanLoungeId != null) {
      context.read<ClientRequestsCubit>().startWatchingRequests(loungeId: cleanLoungeId);
      context.read<RoomCubit>().watchRooms(cleanLoungeId);
    }
    await context.read<LoungeCubit>().fetchLounges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? '';

    return DashboardLayout(
      title: AppStrings.bookings,
      activeRoute: 'Bookings',
      isScrollable: true,
      child: MultiBlocListener(
        listeners: [
          BlocListener<LoginCubit, LoginState>(
            listenWhen: (previous, current) => previous.user?.loungeId != current.user?.loungeId,
            listener: (context, state) {
              final updatedLoungeId = state.user?.loungeId;
              _initRealtimeStreams(updatedLoungeId);
            },
          ),
          BlocListener<BookingCubit, BookingState>(
            listenWhen: (previous, current) => previous.status != current.status,
            listener: (context, state) {
              if (state.status == BookingStatusState.failure) {
                final errMsg = state.errorMessage ?? AppStrings.actionFailed;
                final isShiftError = errMsg.contains('وردية') || errMsg.toLowerCase().contains('shift');

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errMsg),
                    backgroundColor: AppColors.danger,
                    duration: Duration(seconds: isShiftError ? 10 : 4),
                    action: isShiftError ? SnackBarAction(
                      label: '⚡ فتح وردية فورية الآن',
                      textColor: Colors.yellow,
                      onPressed: () async {
                        final user = context.read<LoginCubit>().state.user;
                        final currentLoungeId = user?.loungeId;
                        if (currentLoungeId != null) {
                          final success = await context.read<ShiftCubit>().quickOpenShift(currentLoungeId, 0.0);
                          if (context.mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🟢 تم فتح الوردية بنجاح! يمكنك إضافة الحجز الآن.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      },
                    ) : null,
                  ),
                );
              }
            },
          ),
          BlocListener<ClientRequestsCubit, ClientRequestsState>(
            listenWhen: (previous, current) => previous.unreadCount < current.unreadCount,
            listener: (context, state) {
              final newRequest = state.requests.where((r) => !r.isAttended).firstOrNull;
              if (newRequest != null) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: Colors.black),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '${newRequest.titleAr}: ${newRequest.roomName ?? newRequest.userName ?? ""}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.warning,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
          ),
        ],
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.neonBlue,
          backgroundColor: AppColors.cardBackground,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Bar: Mini Stats + Refresh & New Booking Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: RepaintBoundary(child: _buildLiveStatsHeader(context))),
                    SizedBox(width: 20.w),
                    _buildQuickActionButtons(context, loungeId),
                  ],
                ),

                SizedBox(height: 24.h),

                // Premium Web Dashboard Hybrid 2-Column Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isDesktop = constraints.maxWidth >= 1100;

                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Main Column (Flex 7): Room Grid & Tabs & Sessions
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTabsWithBadges(context),
                                SizedBox(height: 20.h),
                                if (_tabController.index == 0) ...[
                                  RepaintBoundary(child: RoomOccupancyGrid(loungeId: loungeId)),
                                  SizedBox(height: 20.h),
                                ],
                                _buildTabContent(context),
                              ],
                            ),
                          ),
                          SizedBox(width: 20.w),

                          // Right Side Panel (Flex 3): Live Client Requests Panel
                          const Expanded(
                            flex: 3,
                            child: RepaintBoundary(child: LiveRequestsFeed()),
                          ),
                        ],
                      );
                    }

                    // Mobile / Small Screen Single Column Layout
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTabsWithBadges(context),
                        SizedBox(height: 20.h),
                        if (_tabController.index == 0) ...[
                          RepaintBoundary(child: RoomOccupancyGrid(loungeId: loungeId)),
                          SizedBox(height: 20.h),
                          const RepaintBoundary(child: LiveRequestsFeed()),
                          SizedBox(height: 20.h),
                        ],
                        _buildTabContent(context),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context, String loungeId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocSelector<BookingCubit, BookingState, BookingStatusState>(
          selector: (state) => state.status,
          builder: (context, status) {
            final bool isLoading = status == BookingStatusState.loading;

            return MouseRegion(
              cursor: isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
              child: InkWell(
                onTap: isLoading ? null : _handleRefresh,
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.neonBlue,
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          color: AppColors.neonBlue,
                          size: 22.r,
                        ),
                ),
              ),
            );
          },
        ),
        SizedBox(width: 12.w),
        AppButton(
          text: AppStrings.newBooking,
          icon: Icons.add,
          variant: AppButtonVariant.primary,
          onPressed: () => _showAddBookingModal(context, loungeId),
        ),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.bookings != curr.bookings ||
          prev.errorMessage != curr.errorMessage,
      builder: (context, state) {
        if (state.status == BookingStatusState.loading && state.bookings.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(80),
              child: CircularProgressIndicator(color: AppColors.neonBlue),
            ),
          );
        }

        final List<Booking> displayedBookings;
        String emptyMsg = '';
        bool isPending = false;
        bool isAudit = false;

        switch (_tabController.index) {
          case 0:
            displayedBookings = state.bookings
                .where((b) => b.isBookingActive() || (b.status == BookingStatus.upcoming && !b.isSessionExpired()))
                .toList();
            emptyMsg = AppStrings.noActiveBookings;
            break;
          case 1:
            displayedBookings = state.bookings
                .where((b) => b.status == BookingStatus.pending)
                .toList();
            emptyMsg = AppStrings.noNewRequests;
            isPending = true;
            break;
          case 2:
            final activeShift = context.read<ShiftCubit>().state.activeShift;
            final userLounge = context.read<LoginCubit>().state.userLounge;
            displayedBookings = state.bookings
                .where((b) => _isBookingInCurrentShiftOrToday(b, activeShift, userLounge: userLounge))
                .toList();
            emptyMsg = AppStrings.noFinishedBookings;
            isAudit = true;
            break;
          default:
            displayedBookings = [];
        }

        if (displayedBookings.isEmpty) {
          return Center(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48.r, color: AppColors.textMuted),
                  SizedBox(height: 12.h),
                  AppText.body(emptyMsg, color: AppColors.textSecondary, fontSize: 13.sp),
                ],
              ),
            ),
          );
        }

        return RepaintBoundary(
          child: _buildBookingWrap(context, displayedBookings, isPending: isPending, isAudit: isAudit),
        );
      },
    );
  }

  Widget _buildBookingWrap(BuildContext context, List<Booking> bookings, {required bool isPending, bool isAudit = false}) {
    final cubit = context.read<BookingCubit>();

    return Wrap(
      spacing: 16.r,
      runSpacing: 16.r,
      children: bookings.map((booking) {
        if (booking.status == BookingStatus.inProgress) {
          return LiveSessionCard(
            key: ValueKey('live_session_${booking.id}'),
            booking: booking,
          );
        }
        final isBookingPending = booking.status == BookingStatus.pending;
        return BookingCard(
          key: ValueKey('booking_${booking.id}'),
          booking: booking,
          onApprove: isBookingPending ? () => cubit.approveBooking(booking.id) : null,
          onReject: isBookingPending ? () => cubit.rejectBooking(booking.id) : null,
          onConfirmPayment: !isBookingPending && !isAudit && booking.paymentStatus != PaymentStatus.paid
              ? () => _showBookingDetails(context, booking)
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildTabsWithBadges(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      buildWhen: (prev, curr) => prev.bookings != curr.bookings,
      builder: (context, bookingState) {
        return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
          buildWhen: (prev, curr) => prev.requests != curr.requests || prev.filter != curr.filter,
          builder: (context, requestState) {
            final pendingCount = bookingState.bookings.where((b) => b.status == BookingStatus.pending).length;
            final unreadRequestsCount = requestState.unreadCount;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  color: AppColors.neonBlue.withValues(alpha: 0.1),
                ),
                labelColor: AppColors.neonBlue,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.activeBookings),
                        if (unreadRequestsCount > 0) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              '$unreadRequestsCount',
                              style: TextStyle(color: Colors.black, fontSize: 10.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.pendingRequests),
                        if (pendingCount > 0) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.neonPurple,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              '$pendingCount',
                              style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(text: AppStrings.finishedToday),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    final shiftState = context.read<ShiftCubit>().state;
    final activeShiftId = shiftState.activeShift?.id;
    final cubit = context.read<BookingCubit>();

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => BookingDetailsDialog(
        booking: booking,
        onConfirmPayment: (amount, percent, reason) {
          cubit.confirmCashPayment(
            booking.id,
            shiftId: activeShiftId,
            discountAmount: amount,
            discountPercentage: percent,
            discountReason: reason,
          );
        },
        onCancel: () => cubit.rejectBooking(booking.id),
      ),
    );
  }

  bool _isBookingInCurrentShiftOrToday(Booking booking, dynamic activeShift, {Lounge? userLounge}) {
    if (booking.status != BookingStatus.completed) return false;

    // RULE 1: If there is an Active Open Shift -> The Operational Day is defined by the Open Shift!
    if (activeShift != null) {
      if (booking.shiftId != null && booking.shiftId == activeShift.id) {
        return true;
      }
      final DateTime startTime = activeShift.startTime;
      return booking.date.isAfter(startTime.subtract(const Duration(minutes: 15))) ||
          booking.date.isAtSameMomentAs(startTime);
    }

    // RULE 2: If No Active Shift -> Calculate Operational Day based on Lounge Opening Hours / 5:00 AM Threshold
    final now = DateTime.now();

    // Default threshold for overnight lounges: 5:00 AM
    int thresholdHour = 5;

    // If Lounge has registered opening time (e.g. "12:00" or "14:00")
    if (userLounge != null && userLounge.opensAt.isNotEmpty) {
      final parts = userLounge.opensAt.split(':');
      if (parts.isNotEmpty) {
        final parsedHour = int.tryParse(parts[0]);
        if (parsedHour != null && parsedHour >= 0 && parsedHour <= 23) {
          thresholdHour = parsedHour;
        }
      }
    }

    // Calculate Operational Day Start Time
    final DateTime operationalDayStart;
    if (now.hour < thresholdHour) {
      // It is past midnight (e.g. 2:00 AM), so we are still in the operational day that started yesterday at thresholdHour!
      final yesterday = now.subtract(const Duration(days: 1));
      operationalDayStart = DateTime(yesterday.year, yesterday.month, yesterday.day, thresholdHour);
    } else {
      // It is past the threshold hour today (e.g. 2:00 PM), so today's operational day started at thresholdHour today!
      operationalDayStart = DateTime(now.year, now.month, now.day, thresholdHour);
    }

    return booking.date.isAfter(operationalDayStart) || booking.date.isAtSameMomentAs(operationalDayStart);
  }

  Widget _buildLiveStatsHeader(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      buildWhen: (prev, curr) => prev.bookings != curr.bookings,
      builder: (context, state) {
        final activeShift = context.read<ShiftCubit>().state.activeShift;
        final userLounge = context.read<LoginCubit>().state.userLounge;
        final activeCount = state.bookings.where((b) => b.isBookingActive()).length;
        final pendingCount = state.bookings.where((b) => b.status == BookingStatus.pending).length;
        final totalRevenue = state.bookings
            .where((b) => _isBookingInCurrentShiftOrToday(b, activeShift, userLounge: userLounge))
            .fold(0.0, (sum, item) => sum + item.totalPrice);

        return Responsive(
          mobile: Column(
            children: [
              _buildMiniStatCard(AppStrings.activeSessions, activeCount.toString(), AppColors.neonBlue, Icons.sports_esports),
              SizedBox(height: 12.h),
              _buildMiniStatCard(AppStrings.pendingRequests, pendingCount.toString(), AppColors.neonPurple, Icons.notification_important),
            ],
          ),
          desktop: Row(
            children: [
              Expanded(child: _buildMiniStatCard(AppStrings.activeSessions, activeCount.toString(), AppColors.neonBlue, Icons.sports_esports)),
              SizedBox(width: 20.w),
              Expanded(child: _buildMiniStatCard(AppStrings.pendingRequests, pendingCount.toString(), AppColors.neonPurple, Icons.notification_important)),
              SizedBox(width: 20.w),
              Expanded(child: _buildMiniStatCard(AppStrings.dailyTotal, "${totalRevenue.toStringAsFixed(0)} ${AppStrings.egp}", AppColors.success, Icons.account_balance_wallet)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: color, size: 20.r),
          ),
          SizedBox(width: 14.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(label, color: AppColors.textSecondary, fontSize: 12.sp),
              SizedBox(height: 2.h),
              AppText.subHeading(value, color: AppColors.textPrimary, fontSize: 20.sp, fontWeight: FontWeight.bold),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddBookingModal(BuildContext context, String loungeId) {
    context.read<RoomCubit>().watchRooms(loungeId);
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => AddBookingDialog(
        loungeId: loungeId,
      ),
    );
  }
}
