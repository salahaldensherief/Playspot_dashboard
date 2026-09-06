import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_details_dialog.dart';

/// Live Room & Station Occupancy Grid Component for Live Operations.
/// Clarifies empty vs occupied rooms with real-time countdown timers, customer info, and quick booking actions.
class RoomOccupancyGrid extends StatefulWidget {
  final String loungeId;

  const RoomOccupancyGrid({
    super.key,
    required this.loungeId,
  });

  @override
  State<RoomOccupancyGrid> createState() => _RoomOccupancyGridState();
}

class _RoomOccupancyGridState extends State<RoomOccupancyGrid> {
  String _filterType = 'all'; // 'all', 'available', 'occupied'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.loungeId.isNotEmpty) {
        context.read<RoomCubit>().watchRooms(widget.loungeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomCubit, RoomState>(
      builder: (context, roomState) {
        return BlocBuilder<BookingCubit, BookingState>(
          builder: (context, bookingState) {
            final rooms = roomState.rooms;
            if (rooms.isEmpty) {
              return const SizedBox.shrink();
            }

            final activeBookings = bookingState.bookings
                .where((b) => b.isBookingActive())
                .toList();

            // Calculate Counts
            int occupiedCount = 0;
            int availableCount = 0;
            int maintenanceCount = 0;

            for (final room in rooms) {
              if (room.status == RoomStatusEnum.maintenance) {
                maintenanceCount++;
              } else {
                final isOccupied = activeBookings.any((b) => b.roomId == room.id);
                if (isOccupied) {
                  occupiedCount++;
                } else {
                  availableCount++;
                }
              }
            }

            // Filter rooms
            final displayedRooms = rooms.where((room) {
              final isOccupied = activeBookings.any((b) => b.roomId == room.id);
              if (_filterType == 'available') {
                return !isOccupied && room.status != RoomStatusEnum.maintenance;
              } else if (_filterType == 'occupied') {
                return isOccupied;
              } else if (_filterType == 'maintenance') {
                return room.status == RoomStatusEnum.maintenance;
              }
              return true;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Filter Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.meeting_room_outlined, color: AppColors.neonBlue, size: 20.r),
                        SizedBox(width: 8.w),
                        AppText.heading(
                          AppStrings.roomUtilization,
                          fontSize: 16.sp,
                        ),
                      ],
                    ),

                    // Filter Chips Bar
                    Row(
                      children: [
                        _buildFilterChip(
                          label: '${AppStrings.viewAll} (${rooms.length})',
                          value: 'all',
                          color: AppColors.neonBlue,
                        ),
                        SizedBox(width: 8.w),
                        _buildFilterChip(
                          label: 'خالية ($availableCount)',
                          value: 'available',
                          color: AppColors.success,
                        ),
                        SizedBox(width: 8.w),
                        _buildFilterChip(
                          label: 'مشغولة ($occupiedCount)',
                          value: 'occupied',
                          color: AppColors.danger,
                        ),
                        if (maintenanceCount > 0) ...[
                          SizedBox(width: 8.w),
                          _buildFilterChip(
                            label: 'صيانة ($maintenanceCount)',
                            value: 'maintenance',
                            color: AppColors.warning,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // Rooms Grid / Wrap
                Wrap(
                  spacing: 16.r,
                  runSpacing: 16.r,
                  children: displayedRooms.map((room) {
                    final activeBooking = activeBookings.where((b) => b.roomId == room.id).firstOrNull;
                    return _RoomOccupancyCard(
                      key: ValueKey('room_card_${room.id}'),
                      room: room,
                      activeBooking: activeBooking,
                      loungeId: widget.loungeId,
                    );
                  }).toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required Color color,
  }) {
    final isSelected = _filterType == value;
    return InkWell(
      onTap: () => setState(() => _filterType = value),
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? color : AppColors.borderDefault,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RoomOccupancyCard extends StatefulWidget {
  final RoomEntity room;
  final Booking? activeBooking;
  final String loungeId;

  const _RoomOccupancyCard({
    super.key,
    required this.room,
    this.activeBooking,
    required this.loungeId,
  });

  @override
  State<_RoomOccupancyCard> createState() => _RoomOccupancyCardState();
}

class _RoomOccupancyCardState extends State<_RoomOccupancyCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.activeBooking != null) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant _RoomOccupancyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeBooking != oldWidget.activeBooking) {
      if (widget.activeBooking != null) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.abs();
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    if (totalSeconds >= 3600) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final activeBooking = widget.activeBooking;
    final isOccupied = activeBooking != null && activeBooking.isBookingActive();
    final isMaintenance = room.status == RoomStatusEnum.maintenance;

    Color borderColor = AppColors.borderDefault;
    Color statusColor = AppColors.success;
    String statusText = 'خالية';

    if (isMaintenance) {
      borderColor = AppColors.warning.withValues(alpha: 0.5);
      statusColor = AppColors.warning;
      statusText = 'صيانة';
    } else if (isOccupied) {
      borderColor = AppColors.danger.withValues(alpha: 0.6);
      statusColor = AppColors.danger;
      statusText = 'مشغولة';
    }

    Duration remaining = Duration.zero;
    bool isExpired = false;
    if (isOccupied) {
      remaining = activeBooking.remainingDuration();
      isExpired = activeBooking.isSessionExpired();
    }

    return Container(
      width: 320.w,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: isOccupied ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: isOccupied
                ? AppColors.danger.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Room Name & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      room.isOpenArea ? Icons.grid_view_rounded : Icons.sports_esports_rounded,
                      size: 18.r,
                      color: isOccupied ? AppColors.danger : AppColors.neonBlue,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: AppText.subHeading(
                        room.nameAr.isNotEmpty ? room.nameAr : room.nameEn,
                        fontSize: 15.sp,
                        color: AppColors.textPrimary,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Specs Subtitle Bar
          Row(
            children: [
              AppText.body(
                '${room.capacity} ${AppStrings.persons}',
                fontSize: 10.sp,
                color: AppColors.textMuted,
              ),
              SizedBox(width: 8.w),
              AppText.body('•', fontSize: 10.sp, color: AppColors.textMuted),
              SizedBox(width: 8.w),
              AppText.body(
                '${room.controllersCount} ${AppStrings.controllers}',
                fontSize: 10.sp,
                color: AppColors.textMuted,
              ),
              if (room.screenSize.isNotEmpty) ...[
                SizedBox(width: 8.w),
                AppText.body('•', fontSize: 10.sp, color: AppColors.textMuted),
                SizedBox(width: 8.w),
                AppText.body(
                  room.screenSize,
                  fontSize: 10.sp,
                  color: AppColors.neonBlue,
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),

          // Body Content: Occupied vs Available vs Maintenance
          if (isOccupied) ...[
            // Customer Info Box
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.mutedBackground.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: AppColors.neonBlue, size: 14.r),
                          SizedBox(width: 6.w),
                          AppText.subHeading(
                            activeBooking.userName ?? AppStrings.anonymous,
                            fontSize: 13.sp,
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: AppText.body(
                          '${activeBooking.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}',
                          fontSize: 11.sp,
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (activeBooking.userPhone != null && activeBooking.userPhone!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.phone, color: AppColors.neonBlue, size: 12.r),
                        SizedBox(width: 6.w),
                        AppText.body(
                          activeBooking.userPhone!,
                          fontSize: 11.sp,
                          color: AppColors.neonBlue,
                        ),
                        SizedBox(width: 6.w),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: activeBooking.userPhone!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ رقم الهاتف'), duration: Duration(seconds: 2)),
                            );
                          },
                          child: Icon(Icons.copy_rounded, size: 12.r, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 10.h),

            // Remaining Time Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isExpired
                    ? AppColors.danger.withValues(alpha: 0.15)
                    : AppColors.neonBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isExpired ? AppColors.danger : AppColors.neonBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isExpired ? Icons.timer_off : Icons.timer,
                        size: 16.r,
                        color: isExpired ? AppColors.danger : AppColors.neonBlue,
                      ),
                      SizedBox(width: 6.w),
                      AppText.body(
                        isExpired ? AppStrings.timeExpired : AppStrings.remainingTime,
                        fontSize: 11.sp,
                        color: isExpired ? AppColors.danger : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                  AppText.subHeading(
                    isExpired ? '-${_formatDuration(remaining)}' : _formatDuration(remaining),
                    fontSize: 14.sp,
                    color: isExpired ? AppColors.danger : AppColors.neonBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),

            // Action: View Customer & Booking Details
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'تفاصيل الحجز والعميل',
                    icon: Icons.info_outline_rounded,
                    variant: AppButtonVariant.outlined,
                    height: 32.h,
                    onPressed: () {
                      showDialog(
                        context: context,
                        useRootNavigator: false,
                        builder: (_) => BookingDetailsDialog(booking: activeBooking),
                      );
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                AppButton(
                  text: 'تمديد',
                  icon: Icons.add_alarm_rounded,
                  variant: AppButtonVariant.primary,
                  height: 32.h,
                  onPressed: () {
                    _showExtendDialog(context, activeBooking);
                  },
                ),
              ],
            ),
          ] else if (isMaintenance) ...[
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.build_outlined, color: AppColors.warning, size: 16.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: AppText.body(
                      'المحطة تحت الصيانة حالياً وغير متاحة للحجز',
                      fontSize: 11.sp,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Empty Room Information & Quick Start Session Button
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.body('سعر الفردي:', fontSize: 11.sp, color: AppColors.textSecondary),
                      AppText.body(
                        '${room.pricePerHourSingle.toStringAsFixed(0)} ${AppStrings.egp}/ساعة',
                        fontSize: 11.sp,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.body('سعر الزوجي (Multi):', fontSize: 11.sp, color: AppColors.textSecondary),
                      AppText.body(
                        '${room.pricePerHourMulti.toStringAsFixed(0)} ${AppStrings.egp}/ساعة',
                        fontSize: 11.sp,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Start Quick Session Action Button
            AppButton(
              text: '+ بدء حجز سريع على الغرفة',
              icon: Icons.play_arrow_rounded,
              variant: AppButtonVariant.primary,
              width: double.infinity,
              height: 34.h,
              onPressed: () {
                showDialog(
                  context: context,
                  useRootNavigator: false,
                  builder: (_) => AddBookingDialog(
                    loungeId: widget.loungeId,
                    initialRoom: room,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showExtendDialog(BuildContext context, Booking booking) {
    int minutes = 30;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          title: Row(
            children: [
              const Icon(Icons.add_alarm, color: AppColors.neonBlue),
              SizedBox(width: 8.w),
              AppText.subHeading(AppStrings.extendTime, color: AppColors.neonBlue, fontSize: 16.sp),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(
                '${booking.roomName} - ${booking.userName ?? AppStrings.anonymous}',
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                children: [30, 60, 90, 120].map((mins) {
                  final isSelected = minutes == mins;
                  return ChoiceChip(
                    label: Text('+$mins دقيقة', style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12.sp)),
                    selected: isSelected,
                    selectedColor: AppColors.neonBlue,
                    backgroundColor: AppColors.cardBackground,
                    onSelected: (selected) {
                      if (selected) setDialogState(() => minutes = mins);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            AppButton(
              text: AppStrings.cancel,
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            AppButton(
              text: AppStrings.extendTime,
              variant: AppButtonVariant.primary,
              onPressed: () async {
                Navigator.pop(dialogContext);
                final dashboardCubit = context.read<DashboardCubit>();
                final bookingCubit = context.read<BookingCubit>();
                final success = await dashboardCubit.extendSession(booking.id, minutes);
                if (!success) {
                  await bookingCubit.extendBookingDuration(booking.id, minutes);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppStrings.timeExtendedSuccess), backgroundColor: AppColors.success),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
