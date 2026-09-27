import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/client_request_entity.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/live_requests_filter_chip.dart';

class LiveRequestsFilterBar extends StatelessWidget {
  final RequestFilter currentFilter;
  final List<ClientRequestEntity> requests;
  final int unreadCount;

  const LiveRequestsFilterBar({
    super.key,
    required this.currentFilter,
    required this.requests,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClientRequestsCubit>();
    final activeCount = requests.where((r) => !r.isAttended).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          LiveRequestsFilterChip(
            label: AppStrings.all,
            filter: RequestFilter.all,
            currentFilter: currentFilter,
            count: activeCount,
            onSelected: cubit.setFilter,
          ),
          SizedBox(width: 8.w),
          LiveRequestsFilterChip(
            label: AppStrings.callStaff,
            filter: RequestFilter.callStaff,
            currentFilter: currentFilter,
            count: requests.where((r) => r.type == ClientRequestType.callStaff && !r.isAttended).length,
            onSelected: cubit.setFilter,
          ),
          SizedBox(width: 8.w),
          LiveRequestsFilterChip(
            label: AppStrings.canteenOrder,
            filter: RequestFilter.canteenOrders,
            currentFilter: currentFilter,
            count: requests.where((r) => r.isCanteenOrder && !r.isAttended).length,
            onSelected: cubit.setFilter,
          ),
          SizedBox(width: 8.w),
          LiveRequestsFilterChip(
            label: AppStrings.unread,
            filter: RequestFilter.unattendedOnly,
            currentFilter: currentFilter,
            count: unreadCount,
            onSelected: cubit.setFilter,
          ),
        ],
      ),
    );
  }
}
