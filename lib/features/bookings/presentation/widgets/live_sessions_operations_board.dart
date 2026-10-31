import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/booking.dart';
import '../../../requests/presentation/client_requests_cubit.dart';
import '../../../requests/presentation/client_requests_state.dart';
import 'cashier_sessions_workspace.dart';
import 'station_control_drawer.dart';
export '../../domain/entities/live_sessions_operations_groups.dart';

class LiveSessionsOperationsBoard extends StatelessWidget {
  final List<Booking> bookings;
  final ValueChanged<Booking> onShowDetails;
  const LiveSessionsOperationsBoard({
    super.key,
    required this.bookings,
    required this.onShowDetails,
  });
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
        buildWhen: (previous, current) => previous.requests != current.requests,
        builder: (context, state) => CashierSessionsWorkspace(
          bookings: bookings,
          requests: state.requests,
          onManage: (booking) {
            if (booking.status == BookingStatus.inProgress) {
              StationControlDrawer.show(context, booking: booking);
            } else {
              onShowDetails(booking);
            }
          },
        ),
      );
}
