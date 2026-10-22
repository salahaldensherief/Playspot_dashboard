import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  Widget build(BuildContext context) =>
      BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
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
              if (stations.isNotEmpty) ...[
                StationOverviewGrid(stations: stations, onManage: manage),
                const SizedBox(height: 16),
              ],
              CashierSessionsWorkspace(
                bookings: bookings,
                requests: state.requests,
                onManage: manage,
              ),
            ],
          );
        },
      );
}
