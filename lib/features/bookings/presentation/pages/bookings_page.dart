import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_state.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/admin_shift_monitoring_bar.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../auth/presentation/login/login_state.dart';
import '../../../lounges/domain/entities/lounge.dart';
import '../../domain/entities/booking.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../widgets/booking_card.dart';
import '../widgets/add_booking_dialog.dart';
import '../widgets/booking_details_dialog.dart';
import '../widgets/live_session_card.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<LoginCubit>().state.user;
      context.read<BookingCubit>().startWatchingBookings(loungeId: user?.loungeId);
      context.read<LoungeCubit>().fetchLounges();
    });
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
              context.read<BookingCubit>().startWatchingBookings(loungeId: state.user?.loungeId);
            },
          ),
          BlocListener<BookingCubit, BookingState>(
            listenWhen: (previous, current) => previous.status != current.status,
            listener: (context, state) {
              if (state.status == BookingStatusState.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage ?? AppStrings.actionFailed), backgroundColor: AppColors.danger),
                );
              }
            },
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user?.isLoungeOwner == true || user?.isManager == true)
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: AdminShiftMonitoringBar(),
              ),

            _buildLiveStatsHeader(context),

            SizedBox(height: 24.h),

            _buildTopToolbar(context, loungeId),

            SizedBox(height: 24.h),

            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (index) => setState(() {}),
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
                  Tab(text: AppStrings.activeBookings),
                  Tab(text: AppStrings.pendingRequests),
                  Tab(text: AppStrings.finishedToday),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            BlocBuilder<BookingCubit, BookingState>(
              builder: (context, state) {
                if (state.status == BookingStatusState.loading && state.bookings.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(100),
                    child: CircularProgressIndicator(color: AppColors.neonBlue),
                  ));
                }

                final List<Booking> displayedBookings;
                String emptyMsg = '';
                bool isPending = false;
                bool isAudit = false;

                switch (_tabController.index) {
                  case 0:
                    displayedBookings = state.bookings.where((b) => b.status == BookingStatus.upcoming || b.status == BookingStatus.inProgress).toList();
                    emptyMsg = AppStrings.noActiveBookings;
                    break;
                  case 1:
                    displayedBookings = state.bookings.where((b) => b.status == BookingStatus.pending).toList();
                    emptyMsg = AppStrings.noNewRequests;
                    isPending = true;
                    break;
                  case 2:
                    displayedBookings = state.bookings.where((b) => b.status == BookingStatus.completed).toList();
                    emptyMsg = AppStrings.noFinishedBookings;
                    isAudit = true;
                    break;
                  default:
                    displayedBookings = [];
                }

                if (displayedBookings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60.h),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48.r, color: AppColors.textMuted),
                          SizedBox(height: 16.h),
                          AppText.body(emptyMsg, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  );
                }

                return _buildBookingWrap(context, displayedBookings, isPending: isPending, isAudit: isAudit);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingWrap(BuildContext context, List<Booking> bookings, {required bool isPending, bool isAudit = false}) {
    final cubit = context.read<BookingCubit>();

    return Wrap(
      spacing: 20.r,
      runSpacing: 20.r,
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

  Widget _buildLiveStatsHeader(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        final activeCount = state.bookings.where((b) => b.status == BookingStatus.upcoming || b.status == BookingStatus.inProgress).length;
        final pendingCount = state.bookings.where((b) => b.status == BookingStatus.pending).length;
        final totalRevenue = state.bookings
            .where((b) => b.status == BookingStatus.completed)
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
              SizedBox(width: 24.w),
              Expanded(child: _buildMiniStatCard(AppStrings.pendingRequests, pendingCount.toString(), AppColors.neonPurple, Icons.notification_important)),
              SizedBox(width: 24.w),
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
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20.r),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(label, fontSize: 12.sp, color: AppColors.textSecondary),
              AppText.heading(value, fontSize: 18.sp, color: color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopToolbar(BuildContext context, String loungeId) {
    final user = context.read<LoginCubit>().state.user;
    final isMobile = Responsive.isMobile(context);

    return BlocBuilder<LoungeCubit, LoungeState>(
      buildWhen: (previous, current) => previous.lounges != current.lounges,
      builder: (context, state) {
        Lounge? currentLounge;
        if (state.lounges.isNotEmpty) {
          final found = state.lounges.where((l) => l.id == loungeId).toList();
          currentLounge = found.isNotEmpty ? found.first : state.lounges.first;
        }
        final isOpen = currentLounge?.isOpen ?? true;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(isOpen ? Icons.door_front_door : Icons.door_back_door, color: isOpen ? AppColors.success : AppColors.danger),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.subHeading(
                        isOpen ? AppStrings.loungeIsOpen : AppStrings.loungeIsClosed,
                        color: isOpen ? AppColors.success : AppColors.danger,
                        fontSize: 16.sp,
                      ),
                      AppText.body(
                        isOpen ? AppStrings.usersCanBookNow : AppStrings.loungeIsHidden,
                        fontSize: 12.sp,
                      ),
                    ],
                  ),
                ],
              ),
              if (isMobile) SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: isMobile ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final roomCubit = context.read<RoomCubit>();
                      final bookingCubit = context.read<BookingCubit>();
                      final shiftCubit = context.read<ShiftCubit>();

                      roomCubit.watchRooms(loungeId);
                      showDialog(
                        context: context,
                        builder: (context) => MultiBlocProvider(
                          providers: [
                            BlocProvider.value(value: roomCubit),
                            BlocProvider.value(value: bookingCubit),
                            BlocProvider.value(value: shiftCubit),
                          ],
                          child: AddBookingDialog(loungeId: loungeId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    label: AppText.body(AppStrings.newBooking, color: Colors.white, fontWeight: FontWeight.bold),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonBlue,
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                  ),
                  if (user?.canToggleLoungeStatus == true) ...[
                    SizedBox(width: 24.w),
                    if (!isMobile) AppText.body(isOpen ? AppStrings.closeLounge : AppStrings.openLounge, fontWeight: FontWeight.bold),
                    if (!isMobile) SizedBox(width: 8.w),
                    Switch(
                      value: isOpen,
                      activeThumbColor: AppColors.success,
                      onChanged: (val) => context.read<LoungeCubit>().toggleLoungeStatus(loungeId, val),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}