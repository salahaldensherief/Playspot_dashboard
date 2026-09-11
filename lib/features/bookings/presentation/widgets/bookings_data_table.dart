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

class BookingsDataTable extends StatefulWidget {
  final List<Booking>? filteredBookings;
  const BookingsDataTable({super.key, this.filteredBookings});

  @override
  State<BookingsDataTable> createState() => _BookingsDataTableState();
}

class _BookingsDataTableState extends State<BookingsDataTable> {
  int _currentPage = 0;
  final int _pageSize = 15;
  String _selectedStatusFilter = 'all';

  List<Booking> _applyStatusFilter(List<Booking> all) {
    if (_selectedStatusFilter == 'all') return all;
    return all.where((b) => b.status.toDbString() == _selectedStatusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        if (state.status == BookingStatusState.loading && state.bookings.isEmpty) {
          return const TableShimmer(columns: 7);
        }

        final rawList = widget.filteredBookings ?? state.bookings;
        final filteredList = _applyStatusFilter(rawList);
        final totalCount = filteredList.length;
        final totalPages = (totalCount / _pageSize).ceil();

        final startIndex = _currentPage * _pageSize;
        final endIndex = (startIndex + _pageSize) > totalCount ? totalCount : startIndex + _pageSize;
        final pagedBookings = (startIndex < totalCount)
            ? filteredList.sublist(startIndex, endIndex)
            : <Booking>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', AppStrings.all),
                  _buildFilterChip('pending', AppStrings.pending),
                  _buildFilterChip('upcoming', AppStrings.upcoming),
                  _buildFilterChip('in_progress', AppStrings.inProgress),
                  _buildFilterChip('completed', AppStrings.completed),
                  _buildFilterChip('cancelled', AppStrings.cancelled),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Data Table
            DataTableWidget(
              columns: [
                AppStrings.id,
                AppStrings.userLabel,
                AppStrings.roomLabel,
                AppStrings.gaming,
                AppStrings.schedule,
                AppStrings.status,
                AppStrings.actions
              ],
              rows: pagedBookings.map((b) => DataRow(
                onSelectChanged: (_) => _showBookingDetails(context, b),
                cells: [
                  DataCell(AppText.body(b.id.length >= 8 ? b.id.substring(0, 8) : b.id, color: AppColors.textPrimary)),
                  DataCell(AppText.body(b.userName ?? '${AppStrings.userLabel} ${b.userId.length >= 5 ? b.userId.substring(0, 5) : b.userId}', color: AppColors.textPrimary)),
                  DataCell(AppText.body(b.roomName, color: AppColors.textSecondary)),
                  DataCell(AppText.body(AppStrings.gaming, color: AppColors.textSecondary)),
                  DataCell(AppText.body(b.startTime, color: AppColors.textSecondary)),
                  DataCell(_getStatusBadge(b.status.toDbString())),
                  DataCell(_buildActions(context, b)),
                ],
              )).toList(),
            ),

            // Pagination Controls Footer
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    totalCount == 0
                        ? '0 - 0 / 0'
                        : '${startIndex + 1} - $endIndex / $totalCount',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                  ),
                  Row(
                    children: [
                      AppButton(
                        text: AppStrings.back,
                        variant: AppButtonVariant.outlined,
                        fontSize: 12.sp,
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        '${_currentPage + 1} / ${totalPages == 0 ? 1 : totalPages}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      AppButton(
                        text: AppStrings.next,
                        variant: AppButtonVariant.outlined,
                        fontSize: 12.sp,
                        onPressed: (_currentPage + 1) < totalPages
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.neonBlue,
        backgroundColor: AppColors.cardBackground,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedStatusFilter = key;
              _currentPage = 0; // Reset page on filter change
            });
          }
        },
      ),
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
      return booking.paymentStatus == PaymentStatus.paid
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
        onConfirmPayment: (amount, percent, reason) {
          context.read<BookingCubit>().confirmCashPayment(
            booking.id,
            discountAmount: amount,
            discountPercentage: percent,
            discountReason: reason,
          );
        },
        onCancel: () => context.read<BookingCubit>().rejectBooking(booking.id),
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    switch (status) {
      case 'pending': return StatusBadge.warning(AppStrings.pending);
      case 'upcoming': return StatusBadge.info(AppStrings.upcoming);
      case 'in_progress': return StatusBadge.success(AppStrings.inProgress);
      case 'completed': return StatusBadge.success(AppStrings.completed);
      case 'cancelled': return StatusBadge.danger(AppStrings.cancelled);
      default: return StatusBadge.info(status);
    }
  }
}
