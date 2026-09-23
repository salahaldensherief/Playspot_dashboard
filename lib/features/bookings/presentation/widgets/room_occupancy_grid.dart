import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_occupancy_card.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';

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
      buildWhen: (prev, curr) => prev.rooms != curr.rooms,
      builder: (context, roomState) {
        return BlocBuilder<BookingCubit, BookingState>(
          buildWhen: (prev, curr) => prev.bookings != curr.bookings,
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

            final isNarrow = MediaQuery.sizeOf(context).width < 800;

            final titleWidget = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.meeting_room_outlined, color: AppColors.neonBlue, size: 20.r),
                SizedBox(width: 8.w),
                AppText.heading(
                  AppStrings.roomUtilization,
                  fontSize: 15.sp,
                ),
              ],
            );

            final filterChipsBar = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
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
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Filter Badges (Responsive)
                if (isNarrow) ...[
                  titleWidget,
                  SizedBox(height: 10.h),
                  filterChipsBar,
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      titleWidget,
                      Flexible(child: filterChipsBar),
                    ],
                  ),
                ],
                SizedBox(height: 14.h),

                // Rooms Grid / Wrap
                Wrap(
                  spacing: 16.r,
                  runSpacing: 16.r,
                  children: displayedRooms.map((room) {
                    final activeBooking = activeBookings.where((b) => b.roomId == room.id).firstOrNull;
                    return RoomOccupancyCard(
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
