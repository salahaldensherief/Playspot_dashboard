import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_occupancy_grid.dart';

class BookingsCollapsibleOccupancy extends StatefulWidget {
  final String loungeId;
  final bool initialExpanded;

  const BookingsCollapsibleOccupancy({
    super.key,
    required this.loungeId,
    this.initialExpanded = true,
  });

  @override
  State<BookingsCollapsibleOccupancy> createState() => _BookingsCollapsibleOccupancyState();
}

class _BookingsCollapsibleOccupancyState extends State<BookingsCollapsibleOccupancy> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

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
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.neonPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: const Icon(
                          Icons.dashboard_customize_outlined,
                          color: AppColors.neonPurple,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      AppText.subHeading(
                        AppStrings.devicesAndRoomsMap,
                        fontSize: 14.sp,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.neonBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          _isExpanded ? 'إخفاء الخريطة' : 'عرض الخريطة',
                          style: TextStyle(
                            color: AppColors.neonBlue,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(color: AppColors.borderDefault, height: 1),
            Padding(
              padding: EdgeInsets.all(14.r),
              child: RoomOccupancyGrid(loungeId: widget.loungeId),
            ),
          ],
        ],
      ),
    );
  }
}
