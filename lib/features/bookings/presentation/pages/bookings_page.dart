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
import '../../../lounges/domain/entities/lounge.dart';
import '../../domain/entities/booking.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../widgets/booking_card.dart';

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
            listener: (context, state) {
              if (state.status == BookingStatusState.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage ?? 'Action Failed'), backgroundColor: AppColors.danger),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<BookingCubit, BookingState>(
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

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopToolbar(context, loungeId),
                  SizedBox(height: 24.h),
                  
                  // 1. Pending Section
                  _buildSectionHeader(AppStrings.pendingRequests, pendingBookings.length, AppColors.neonPurple),
                  SizedBox(height: 16.h),
                  _buildBookingGrid(context, bookingCubit, pendingBookings, isPending: true),
                  
                  SizedBox(height: 40.h),
                  
                  // 2. Active Section
                  _buildSectionHeader(AppStrings.activeBookings, activeBookings.length, AppColors.neonBlue),
                  SizedBox(height: 16.h),
                  _buildBookingGrid(context, bookingCubit, activeBookings, isPending: false),

                  SizedBox(height: 40.h),

                  // 3. Today's Audit Log
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader(AppStrings.finishedToday, finishedToday.length, AppColors.success),
                      _buildRevenueCard(totalRevenueToday),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildBookingGrid(context, bookingCubit, finishedToday, isPending: false, isAudit: true),
                ],
              ),
            );
          },
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
    return BlocBuilder<LoungeCubit, LoungeState>(
      builder: (context, state) {
        Lounge? currentLounge;
        if (state.lounges.isNotEmpty) {
          final found = state.lounges.where((l) => l.id == loungeId).toList();
          currentLounge = found.isNotEmpty ? found.first : state.lounges.first;
        }
        final isOpen = currentLounge?.isOpen ?? true;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.borderDefault)),
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
                      AppText.subHeading(isOpen ? "Lounge is OPEN" : "Lounge is CLOSED", color: isOpen ? AppColors.success : AppColors.danger, fontSize: 16.sp),
                      AppText.body(isOpen ? "Users can book now" : "Lounge is hidden", fontSize: 12.sp),
                    ],
                  ),
                ],
              ),
              Switch(value: isOpen, activeColor: AppColors.success, onChanged: (val) => context.read<LoungeCubit>().toggleLoungeStatus(loungeId, val)),
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
        child: Center(child: AppText.body(isAudit ? "No finished bookings yet" : (isPending ? "No new requests" : "No active bookings"), color: AppColors.textSecondary)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20.w,
        mainAxisSpacing: 20.h,
        mainAxisExtent: 320.h,
      ),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingCard(
          key: ValueKey('booking_${booking.id}_${booking.status}'),
          booking: booking,
          onApprove: isPending ? () => cubit.approveBooking(booking.id) : null,
          onReject: isPending ? () => cubit.rejectBooking(booking.id) : null,
          onConfirmPayment: !isPending && !isAudit && booking.paymentStatus != 'paid'
              ? () => cubit.confirmCashPayment(booking.id)
              : null,
        );
      },
    );
  }
}
