import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import '../cubit/booking_cubit.dart';

class BookingsDataTable extends StatelessWidget {
  const BookingsDataTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
        }
        
        final bookings = state is BookingLoaded ? state.bookings : [];
        
        return DataTableWidget(
          columns: const ['ID', 'Customer', 'Room', 'Activity', 'Schedule', 'Status', 'Confirm Payment'],
          rows: bookings.map((b) => DataRow(
            cells: [
              DataCell(Text(b.id.substring(0, 8), style: const TextStyle(color: AppColors.textPrimary))),
              DataCell(Text('${AppStrings.userLabel} ${b.userId.substring(0, 5)}', style: const TextStyle(color: AppColors.textPrimary))),
              DataCell(Text('${AppStrings.roomLabel} ${b.roomId.substring(0, 3)}', style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(Text(AppStrings.gaming, style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(Text('Today 14:00', style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(_getStatusBadge(b.status.name)),
              DataCell(
                AppButton(
                  text: AppStrings.confirmCash,
                  variant: AppButtonVariant.primary,
                  onPressed: () => context.read<BookingCubit>().confirmCashPayment(b.id),
                ),
              ),
            ],
          )).toList(),
        );
      },
    );
  }

  Widget _getStatusBadge(String status) {
    switch (status) {
      case 'upcoming': return StatusBadge.info('Upcoming');
      case 'completed': return StatusBadge.success('Completed');
      case 'cancelled': return StatusBadge.danger('Cancelled');
      default: return StatusBadge.info(status);
    }
  }
}
