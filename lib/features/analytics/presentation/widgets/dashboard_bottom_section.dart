import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/widgets/room_status_card.dart';
import 'package:play_spot_dashboard/features/reviews/presentation/widgets/lounge_reviews_card.dart';
import 'live_bookings_feed.dart';
import 'top_lounges_card.dart';

class DashboardBottomSection extends StatelessWidget {
  final bool isSuperAdmin;
  const DashboardBottomSection({super.key, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isSuperAdmin) ...[
          const LiveBookingsFeed(),
          SizedBox(height: 20.h),
          const RoomStatusCard(),
          SizedBox(height: 20.h),
          const LoungeReviewsCard(),
        ],
        if (isSuperAdmin) const TopLoungesCard(),
      ],
    );
  }
}
