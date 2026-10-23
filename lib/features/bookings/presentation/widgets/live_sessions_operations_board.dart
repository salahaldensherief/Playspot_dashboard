import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import '../../domain/entities/booking.dart';
import '../../../requests/presentation/client_requests_cubit.dart';
import '../../../requests/presentation/client_requests_state.dart';
import '../../../rooms/domain/entities/room_entity.dart';
import '../../domain/entities/station_operational_state.dart';
import 'cashier_sessions_workspace.dart';
import 'station_overview_grid.dart';
import 'station_control_drawer.dart';
export '../../domain/entities/live_sessions_operations_groups.dart';

class LiveSessionsOperationsBoard extends StatelessWidget {
  final List<Booking> bookings;
  final ValueChanged<Booking> onShowDetails;
  final List<RoomEntity> rooms;
  final bool roomDataFresh;
  const LiveSessionsOperationsBoard({
    super.key,
    required this.bookings,
    required this.onShowDetails,
    this.rooms = const [],
    this.roomDataFresh = false,
  });
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
    buildWhen: (previous, current) => previous.requests != current.requests,
    builder: (context, state) {
      void manage(Booking booking) {
        if (booking.status == BookingStatus.inProgress) {
          StationControlDrawer.show(context, booking: booking);
        } else {
          onShowDetails(booking);
        }
      }

      final stations = StationOperationalState.build(
        rooms: rooms,
        bookings: bookings,
        requests: state.requests,
        roomDataFresh: roomDataFresh,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CashierSessionsWorkspace(
            bookings: bookings,
            requests: state.requests,
            onManage: manage,
          ),
          if (stations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Material(
              color: AppColors.cardBackground,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.borderDefault),
              ),
              child: ExpansionTile(
                key: const PageStorageKey('station_overview_expansion'),
                initiallyExpanded: false,
                maintainState: true,
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                leading: const Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.primary,
                ),
                title: Text(
                  'stationOverview'.tr(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${stations.where((item) => item.active != null).length} / ${stations.length}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                children: [
                  StationOverviewGrid(
                    stations: stations,
                    onManage: manage,
                    showHeader: false,
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}
