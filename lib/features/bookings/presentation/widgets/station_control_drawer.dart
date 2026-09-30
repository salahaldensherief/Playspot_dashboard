import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/di/provider_scope.dart';
import '../../../../art_core/theme/operations_tokens.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../core/responsive/app_breakpoints.dart';
import '../../../analytics/presentation/dashboard_cubit.dart';
import '../../../auth/presentation/login/login_cubit.dart';
import '../../../rooms/presentation/cubit/room_cubit.dart';
import '../../../permissions/presentation/cubit/permissions_cubit.dart';
import '../../../permissions/presentation/cubit/permissions_state.dart';
import '../../../requests/presentation/client_requests_cubit.dart';
import '../../../requests/presentation/client_requests_state.dart';
import '../../domain/entities/booking.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import 'cashier_session_details.dart';
import 'session_operations_summary.dart';
import 'session_control_actions.dart';
import 'session_clock_host.dart';
import 'session_request_actions.dart';

class StationControlDrawer extends StatelessWidget {
  final Booking booking;
  final VoidCallback onClose;
  const StationControlDrawer({
    super.key,
    required this.booking,
    required this.onClose,
  });

  static void show(BuildContext parentContext, {required Booking booking}) {
    final permissions = parentContext.read<PermissionsCubit?>();
    final login = parentContext.read<LoginCubit?>();
    showGeneralDialog<void>(
      context: parentContext,
      barrierDismissible: true,
      barrierLabel: 'cashier.close'.tr(),
      pageBuilder: (dialogContext, animation, secondary) =>
          MultiBlocProviderScope(
            providers: [
              BlocProvider.value(value: parentContext.read<DashboardCubit>()),
              BlocProvider.value(value: parentContext.read<BookingCubit>()),
              BlocProvider.value(value: parentContext.read<RoomCubit>()),
              BlocProvider.value(
                value: parentContext.read<ClientRequestsCubit>(),
              ),
              if (login != null) BlocProvider.value(value: login),
              if (permissions != null) BlocProvider.value(value: permissions),
            ],
            child: SafeArea(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Material(
                  child: SizedBox(
                    width: AppBreakpoints.isMobile(dialogContext)
                        ? MediaQuery.sizeOf(dialogContext).width
                        : OperationsTokens.railWidth * 2,
                    child: SessionClockHost(
                      child: StationControlDrawer(
                        booking: booking,
                        onClose: () => Navigator.of(dialogContext).pop(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _controls(BuildContext context, Booking current) {
    final permissions = context.read<PermissionsCubit?>();
    if (permissions == null) return SessionControlActions(booking: current);
    return BlocBuilder<PermissionsCubit, PermissionsState>(
      buildWhen: (previous, next) => previous != next,
      builder: (_, state) =>
          SessionControlActions(key: ValueKey(current.id), booking: current),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppButton(
        text: 'cashier.close'.tr(),
        height: 48,
        variant: AppButtonVariant.text,
        onPressed: onClose,
      ),
      Expanded(
        child: BlocBuilder<BookingCubit, BookingState>(
          buildWhen: (previous, current) =>
              previous.bookings != current.bookings ||
              previous.status != current.status,
          builder: (context, state) {
            final matching = state.bookings.where(
              (item) => item.id == booking.id,
            );
            if (matching.isEmpty &&
                state.status == BookingStatusState.success) {
              return Text('cashier.ended'.tr());
            }
            final current = matching.isEmpty ? booking : matching.first;
            return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
              buildWhen: (previous, next) => previous.requests != next.requests,
              builder: (context, requestsState) {
                final requests = requestsState.requests
                    .where(
                      (r) =>
                          !r.isAttended &&
                          (r.bookingId == current.id ||
                              (r.bookingId == null &&
                                  r.roomId == current.roomId)),
                    )
                    .toList();
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(OperationsTokens.padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CashierSessionDetails(
                        summary: SessionOperationsSummary.fromBookings(
                          current,
                          state.bookings,
                        ),
                        requests: requests,
                      ),
                      const SizedBox(height: OperationsTokens.gap),
                      for (final request in requests)
                        SessionRequestActions(request: request),
                      _controls(context, current),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}
