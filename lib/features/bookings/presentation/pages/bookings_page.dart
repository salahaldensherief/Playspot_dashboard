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
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/admin_shift_monitoring_bar.dart';
import '../../../lounges/domain/entities/lounge.dart';
import '../../domain/entities/booking.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../widgets/booking_card.dart';
import '../widgets/add_booking_dialog.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? '';
    final bookingCubit = context.read<BookingCubit>();

    return DashboardLayout(
      title: AppStrings.bookings,
      activeRoute: 'Bookings',
      child: MultiBlocListener(
        listeners: [
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
            _buildTopToolbar(context, loungeId),
            SizedBox(height: 24.h),
            BlocBuilder<BookingCubit, BookingState>(
              buildWhen: (previous, current) => 
                  previous.status != current.status || 
                  previous.bookings != current.bookings,
              builder: (context, bookingState) {
                if (bookingState.status == BookingStatusState.loading && bookingState.bookings.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
                }

                final pendingBookings = bookingState.bookings.where((b) => b.status == BookingStatus.pending).toList();
                final activeBookings = bookingState.bookings.where((b) => b.status == BookingStatus.upcoming).toList();
                final finishedToday = bookingState.bookings.where((b) => b.status == BookingStatus.completed).toList();

                double totalRevenueToday = 0;
                for (var b in finishedToday) {
                  totalRevenueToday += b.totalPrice;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(AppStrings.pendingRequests, pendingBookings.length, AppColors.neonPurple),
                    SizedBox(height: 16.h),
                    _buildBookingGrid(context, bookingCubit, pendingBookings, isPending: true),
                    
                    SizedBox(height: 40.h),
                    
                    _buildSectionHeader(AppStrings.activeBookings, activeBookings.length, AppColors.neonBlue),
                    SizedBox(height: 16.h),
                    _buildBookingGrid(context, bookingCubit, activeBookings, isPending: false),

                    SizedBox(height: 40.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader(AppStrings.finishedToday, finishedToday.length, AppColors.success),
                        if (user?.canViewReports == true) _buildRevenueCard(totalRevenueToday),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _buildBookingGrid(context, bookingCubit, finishedToday, isPending: false, isAudit: true),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(double amount) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, color: AppColors.success, size: 20),
          SizedBox(width: 8.w),
          AppText.body("${AppStrings.dailyTotal}: ", fontWeight: FontWeight.bold),
          AppText.subHeading("${amount.toStringAsFixed(0)} ${AppStrings.egp}", color: AppColors.success),
        ],
      ),
    );
  }

  Widget _buildTopToolbar(BuildContext context, String loungeId) {
    final user = context.read<LoginCubit>().state.user;
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Row(
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
                    AppText.body(isOpen ? AppStrings.closeLounge : AppStrings.openLounge, fontWeight: FontWeight.bold),
                    SizedBox(width: 8.w),
                    Switch(
                      value: isOpen, 
                      activeColor: AppColors.success, 
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

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(width: 4.w, height: 24.h, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2.r))),
        SizedBox(width: 12.w),
        AppText.heading(title, fontSize: 20.sp),
        SizedBox(width: 12.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
          child: AppText.body(count.toString(), color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBookingGrid(BuildContext context, BookingCubit cubit, List<Booking> bookings, {required bool isPending, bool isAudit = false}) {
    if (bookings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(color: AppColors.cardBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.borderDefault)),
        child: Center(child: AppText.body(isAudit ? AppStrings.noFinishedBookings : (isPending ? AppStrings.noNewRequests : AppStrings.noActiveBookings), color: AppColors.textSecondary)),
      );
    }

    final shiftState = context.read<ShiftCubit>().state;
    final activeShiftId = shiftState.activeShift?.id;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic column count based on available width
        int crossAxisCount = 3;
        if (constraints.maxWidth < 900) crossAxisCount = 2;
        if (constraints.maxWidth < 600) crossAxisCount = 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20.r,
            mainAxisSpacing: 20.r,
            childAspectRatio: 0.9, // Dynamic ratio instead of fixed mainAxisExtent
          ),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return BookingCard(
              key: ValueKey('booking_${booking.id}'),
              booking: booking,
              onApprove: isPending ? () => cubit.approveBooking(booking.id) : null,
              onReject: isPending ? () => cubit.rejectBooking(booking.id) : null,
              onConfirmPayment: !isPending && !isAudit && booking.paymentStatus != PaymentStatus.paid
                  ? () => cubit.confirmCashPayment(booking.id, shiftId: activeShiftId)
                  : null,
            );
          },
        );
      },
    );
  }
}
