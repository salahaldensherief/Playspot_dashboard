import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';

class BookingsFinishedDataTable extends StatelessWidget {
  final List<Booking> bookings;
  final ValueChanged<Booking> onShowDetails;

  const BookingsFinishedDataTable({
    super.key,
    required this.bookings,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DataTableWidget(
        columns: [
          AppStrings.customer,
          AppStrings.roomLabel,
          AppStrings.time,
          AppStrings.amount,
          AppStrings.paymentMethod,
          AppStrings.actions,
        ],
        rows: bookings.map((b) {
          return DataRow(
            cells: [
              DataCell(Text(
                b.userName ?? AppStrings.anonymous,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              )),
              DataCell(Text(
                b.roomName,
                style: const TextStyle(
                  color: AppColors.neonPurple,
                  fontWeight: FontWeight.w600,
                ),
              )),
              DataCell(Text(
                b.startTime,
                style: const TextStyle(color: AppColors.textSecondary),
              )),
              DataCell(Text(
                '${b.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}',
                style: const TextStyle(
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.bold,
                ),
              )),
              DataCell(StatusBadge(
                text: b.paymentMethod == 'manual_transfer' ? 'محفظة' : 'كاش',
                color: b.paymentMethod == 'manual_transfer'
                    ? AppColors.neonBlue
                    : AppColors.warning,
              )),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (b.status == BookingStatus.pending) ...[
                      IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                        tooltip: AppStrings.approve,
                        onPressed: () => context.read<BookingCubit>().approveBooking(b.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_rounded, color: AppColors.danger),
                        tooltip: AppStrings.reject,
                        onPressed: () => context.read<BookingCubit>().rejectBooking(b.id),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, color: AppColors.neonBlue),
                      tooltip: AppStrings.details,
                      onPressed: () => onShowDetails(b),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
