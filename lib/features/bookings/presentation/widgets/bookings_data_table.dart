import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../cubit/booking_cubit.dart';
import '../../domain/entities/booking.dart';
import '../cubit/booking_state.dart';
import 'booking_details_dialog.dart';

class BookingsDataTable extends StatelessWidget {
  final List<Booking>? filteredBookings;
  const BookingsDataTable({super.key, this.filteredBookings});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        if (state.status == BookingStatusState.loading && state.bookings.isEmpty) {
          return const TableShimmer(columns: 7);
        }
        
        final bookings = filteredBookings ?? state.bookings;
        
        return DataTableWidget(
          columns: [
            AppStrings.id,
            AppStrings.userLabel, 
            AppStrings.roomLabel, 
            AppStrings.gaming, 
            AppStrings.schedule, 
            AppStrings.status, 
            AppStrings.actions
          ],
          rows: bookings.map((b) => DataRow(
            onSelectChanged: (_) => _showBookingDetails(context, b),
            cells: [
              DataCell(AppText.body(b.id.substring(0, 8), color: AppColors.textPrimary)),
              DataCell(AppText.body(b.userName ?? '${AppStrings.userLabel} ${b.userId.substring(0, 5)}', color: AppColors.textPrimary)),
              DataCell(AppText.body(b.roomName, color: AppColors.textSecondary)),
              DataCell(AppText.body(AppStrings.gaming, color: AppColors.textSecondary)),
              DataCell(AppText.body(b.startTime, color: AppColors.textSecondary)),
              DataCell(_getStatusBadge(b.status.toString().split('.').last)),
              DataCell(_buildActions(context, b)),
            ],
          )).toList(),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context, Booking booking) {
    // إذا كان الحجز ينتظر الموافقة، نعرض أزرار القبول والرفض
    if (booking.status == BookingStatus.pending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            text: AppStrings.approve,
            variant: AppButtonVariant.primary,
            onPressed: () => context.read<BookingCubit>().approveBooking(booking.id),
          ),
          SizedBox(width: 8.w),
          AppButton(
            text: AppStrings.reject,
            variant: AppButtonVariant.outlined,
            onPressed: () => context.read<BookingCubit>().rejectBooking(booking.id),
          ),
        ],
      );
    }

    // إذا تم قبول الحجز (Active)، نعرض زر تأكيد الدفع إذا لم يتم الدفع بعد
    if (booking.status == BookingStatus.upcoming) {
      return booking.paymentStatus == 'completed'
        ? const Icon(Icons.check_circle, color: AppColors.success)
        : AppButton(
            text: AppStrings.confirmCash,
            variant: AppButtonVariant.primary,
            onPressed: () => context.read<BookingCubit>().confirmCashPayment(booking.id),
          );
    }

    // إذا اكتمل الحجز تماماً
    if (booking.status == BookingStatus.completed) {
      return const Icon(Icons.verified, color: AppColors.success);
    }

    return const SizedBox.shrink();
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (_) => BookingDetailsDialog(
        booking: booking,
        onConfirmPayment: () => context.read<BookingCubit>().confirmCashPayment(booking.id),
        onCancel: () => context.read<BookingCubit>().rejectBooking(booking.id),
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    switch (status) {
      case 'pending': return StatusBadge.warning(AppStrings.pending);
      case 'upcoming': return StatusBadge.info(AppStrings.upcoming);
      case 'completed': return StatusBadge.success(AppStrings.completed);
      case 'cancelled': return StatusBadge.danger(AppStrings.cancelled);
      default: return StatusBadge.info(status);
    }
  }
}
