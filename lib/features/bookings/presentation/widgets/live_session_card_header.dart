import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';

class LiveSessionCardHeader extends StatelessWidget {
  final Booking booking;
  final Color accent;
  final VoidCallback onSwapRoom;
  final VoidCallback onOpenStationControl;

  const LiveSessionCardHeader({
    super.key,
    required this.booking,
    required this.accent,
    required this.onSwapRoom,
    required this.onOpenStationControl,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return Container(
      color: accent.withValues(alpha: 0.08),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.sports_esports_rounded, size: 16.r, color: accent),
                SizedBox(width: 6.w),
                Flexible(
                  child: AppText.subHeading(
                    booking.roomName,
                    fontSize: 13.sp,
                    color: AppColors.textPrimary,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 6.w),
                Tooltip(
                  message: AppStrings.swapRoom,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6.r),
                    onTap: onSwapRoom,
                    child: Container(
                      padding: EdgeInsets.all(5.r),
                      decoration: BoxDecoration(
                        color: AppColors.neonBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        size: 14,
                        color: AppColors.neonBlue,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Tooltip(
                  message: AppStrings.stationControlDrawer,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6.r),
                    onTap: onOpenStationControl,
                    child: Container(
                      padding: EdgeInsets.all(5.r),
                      decoration: BoxDecoration(
                        color: AppColors.neonPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: AppColors.neonPurple,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingLiveDot(color: accent),
                SizedBox(width: 5.w),
                Text(
                  booking.isOpenEnded
                      ? 'cashier.open'.tr()
                      : AppStrings.inProgress,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingLiveDot extends StatefulWidget {
  final Color color;
  const _PulsingLiveDot({required this.color});

  @override
  State<_PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<_PulsingLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: 7.r,
        height: 7.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _animation.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _animation.value * 0.8),
              blurRadius: 5,
              spreadRadius: 1.5,
            ),
          ],
        ),
      ),
    );
  }
}
