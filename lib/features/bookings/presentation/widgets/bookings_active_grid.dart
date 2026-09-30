import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_empty_state_widget.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_card.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/bookings_finished_data_table.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/live_session_card.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/live_sessions_operations_board.dart';

class BookingsActiveGrid extends StatelessWidget {
  final List<Booking> bookings;
  final bool isTableView;
  final ValueChanged<Booking> onShowDetails;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;
  final bool prioritizeOperations;

  const BookingsActiveGrid({
    super.key,
    required this.bookings,
    required this.isTableView,
    required this.onShowDetails,
    required this.onApprove,
    required this.onReject,
    this.prioritizeOperations = false,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: AppEmptyStateWidget(
          icon: Icons.inbox_rounded,
          title: AppStrings.noMatchingBookings,
        ),
      );
    }

    if (isTableView) {
      return BookingsFinishedDataTable(
        bookings: bookings,
        onShowDetails: onShowDetails,
      );
    }

    if (prioritizeOperations) {
      return LiveSessionsOperationsBoard(
        bookings: bookings,
        onShowDetails: onShowDetails,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420.w,
        mainAxisExtent: 515.h,
        crossAxisSpacing: 14.r,
        mainAxisSpacing: 14.r,
      ),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        if (b.status == BookingStatus.inProgress) {
          return LiveSessionCard(
            key: ValueKey('live_${b.id}'),
            booking: b,
            width: double.infinity,
          );
        }
        return BookingCard(
          key: ValueKey('booking_${b.id}'),
          booking: b,
          width: double.infinity,
          onApprove: b.status == BookingStatus.pending
              ? () => onApprove(b.id)
              : null,
          onReject: b.status == BookingStatus.pending
              ? () => onReject(b.id)
              : null,
          onConfirmPayment: () => onShowDetails(b),
        );
      },
    );
  }
}
