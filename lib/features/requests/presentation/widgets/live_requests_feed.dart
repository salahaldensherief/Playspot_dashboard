import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/live_requests_empty_state.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/live_requests_filter_bar.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/live_requests_header.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/request_card.dart';

/// Premium Responsive Live Operations Requests Feed handling all client mobile request types.
class LiveRequestsFeed extends StatelessWidget {
  const LiveRequestsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.requests != curr.requests ||
          prev.filter != curr.filter,
      builder: (context, state) {
        final requests = state.filteredRequests;
        final unreadCount = state.unreadCount;

        return Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.borderDefault,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              LiveRequestsHeader(
                unreadCount: unreadCount,
                isLoading: state.status == ClientRequestsStatus.loading && requests.isEmpty,
              ),
              SizedBox(height: 14.h),

              // Filter Bar
              LiveRequestsFilterBar(
                currentFilter: state.filter,
                requests: state.requests,
                unreadCount: unreadCount,
              ),
              SizedBox(height: 16.h),

              // Content Grid / Empty State
              if (requests.isEmpty)
                const LiveRequestsEmptyState()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double totalWidth = constraints.maxWidth;
                    int columns = 1;
                    if (totalWidth >= 1100) {
                      columns = 3;
                    } else if (totalWidth >= 600) {
                      columns = 2;
                    }

                    final double cardWidth = (totalWidth - ((columns - 1) * 14.w)) / columns;

                    return Wrap(
                      spacing: 14.w,
                      runSpacing: 14.h,
                      children: requests.take(15).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final request = entry.value;

                        return SizedBox(
                          key: ValueKey('${request.id}_$index'),
                          width: cardWidth,
                          child: RequestCard(request: request),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
