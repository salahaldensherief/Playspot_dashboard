import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/widgets/room_status_card.dart';
import 'live_bookings_feed.dart';
import 'recent_activities.dart';
import 'top_lounges_card.dart';

class DashboardBottomSection extends StatelessWidget {
  final bool isSuperAdmin;
  const DashboardBottomSection({super.key, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              if (!isSuperAdmin) ...[
                const LiveBookingsFeed(),
                SizedBox(height: 24.h),
              ],
              if (isSuperAdmin) const TopLoungesCard(),
            ],
          ),
        ),
        SizedBox(width: 24.w),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              const RecentActivityCard(),
              if (!isSuperAdmin) ...[
                SizedBox(height: 24.h),
                const RoomStatusCard(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
