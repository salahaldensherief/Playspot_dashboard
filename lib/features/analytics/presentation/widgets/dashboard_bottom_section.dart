import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/widgets/room_status_card.dart';
import 'package:play_spot_dashboard/features/reviews/presentation/widgets/lounge_reviews_card.dart';
import 'live_bookings_feed.dart';
import 'top_lounges_card.dart';

class DashboardBottomSection extends StatelessWidget {
  final bool isSuperAdmin;
  const DashboardBottomSection({super.key, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final isLoungeOwner = user?.isLoungeOwner ?? false;

    return Column(
      children: [
        if (!isSuperAdmin) ...[
          const LiveBookingsFeed(),
          SizedBox(height: 20.h),
          const RoomStatusCard(),
          if (isLoungeOwner) ...[
            SizedBox(height: 20.h),
            const LoungeReviewsCard(),
          ],
        ],
        if (isSuperAdmin) const TopLoungesCard(),
      ],
    );
  }
}
