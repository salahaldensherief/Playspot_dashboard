import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../art_core/theme/operations_tokens.dart';
import '../../../bookings/presentation/cubit/booking_cubit.dart';
import '../../../bookings/presentation/cubit/booking_state.dart';
import '../../../bookings/presentation/widgets/live_sessions_operations_board.dart';
import '../../../bookings/presentation/widgets/station_control_drawer.dart';
import 'live_feed_header.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../bookings/presentation/widgets/cashier_sessions_loading.dart';
import '../dashboard_cubit.dart';
import '../dashboard_state.dart';
import '../../../bookings/domain/entities/booking.dart';
import '../../../bookings/presentation/widgets/session_clock_host.dart';

class LiveBookingsFeed extends StatelessWidget {
  const LiveBookingsFeed({super.key});
  @override
  Widget build(BuildContext context) => SessionClockHost(
    child: BlocSelector<DashboardCubit, DashboardState, List<Booking>>(
      selector: (state) => state.activeSessionsList,
      builder: (context, live) => BlocBuilder<BookingCubit, BookingState>(
        buildWhen: (previous, current) =>
            previous.bookings != current.bookings ||
            previous.status != current.status,
        builder: (context, state) {
          final bookings = {
            ...{for (final item in state.bookings) item.id: item},
            ...{for (final item in live) item.id: item},
          }.values.toList();
          return Container(
            decoration: OperationsTokens.panel,
            padding: const EdgeInsets.all(OperationsTokens.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LiveFeedHeader(
                  activeCount: bookings
                      .where((b) => b.status == BookingStatus.inProgress)
                      .length,
                  isLoading:
                      state.bookings.isEmpty &&
                      state.status == BookingStatusState.loading,
                ),
                const SizedBox(height: OperationsTokens.gap),
                if (state.status == BookingStatusState.loading &&
                    bookings.isEmpty)
                  const CashierSessionsLoading()
                else if (state.status == BookingStatusState.failure) ...[
                  Text('cashier.loadFailed'.tr()),
                  AppButton(
                    text: 'retry'.tr(),
                    height: 48,
                    onPressed: () {
                      final cubit = context.read<BookingCubit>();
                      final scope = cubit.watchedEntityId;
                      if (scope != null)
                        cubit.startWatchingBookings(
                          loungeId: scope == 'all' ? null : scope,
                          forceRefresh: true,
                        );
                    },
                  ),
                ] else
                  LiveSessionsOperationsBoard(
                    bookings: bookings,
                    onShowDetails: (booking) =>
                        StationControlDrawer.show(context, booking: booking),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
