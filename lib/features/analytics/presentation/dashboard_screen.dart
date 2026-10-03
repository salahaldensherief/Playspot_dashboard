import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'dashboard_cubit.dart';
import 'lounge_stats_cubit.dart';
import 'widgets/dashboard_time_range_selector.dart';
import 'widgets/lounge_owner_dashboard_view.dart';
import 'widgets/super_admin_dashboard_view.dart';

/// Operational Cockpit DashboardScreen for PlaySpot.
/// Provides responsive, differentiated operational layouts across Desktop, Tablet, and Mobile.
class DashboardScreen extends StatefulWidget {
  final UserRole role;

  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardTimeRange _selectedTimeRange = DashboardTimeRange.week;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final loungeId = context.read<LoginCubit>().state.user?.loungeId;
      _initRealtimeStreams(loungeId);
    });
  }

  void _initRealtimeStreams(String? loungeId) {
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty)
        ? loungeId.trim()
        : null;

    if (widget.role != UserRole.superAdmin) {
      context.read<LoungeStatsCubit>().fetchStats(cleanLoungeId);
      context.read<DashboardCubit>().startWatchingActiveSessions(
        loungeId: cleanLoungeId,
      );
      context.read<BookingCubit>().startWatchingBookings(
        loungeId: cleanLoungeId,
      );
      if (cleanLoungeId != null) {
        context.read<RoomCubit>().watchRooms(cleanLoungeId);
        context.read<ClientRequestsCubit>().startWatchingRequests(
          loungeId: cleanLoungeId,
        );
      }
    } else {
      context.read<DashboardCubit>().loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = widget.role == UserRole.superAdmin;

    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (prev, curr) => prev.user?.loungeId != curr.user?.loungeId,
      listener: (context, loginState) {
        final loungeId = loginState.user?.loungeId;
        _initRealtimeStreams(loungeId);
      },
      child: DashboardLayout(
        title: AppStrings.dashboard,
        activeRoute: 'Dashboard',
        isScrollable: false,
        child: isSuperAdmin
            ? SuperAdminDashboardView(
                timeRange: _selectedTimeRange,
                onTimeRangeChanged: (range) {
                  setState(() => _selectedTimeRange = range);
                  context.read<DashboardCubit>().loadDashboardData(
                    revenuePeriod: range.name,
                  );
                },
              )
            : LoungeOwnerDashboardView(
                timeRange: _selectedTimeRange,
                onTimeRangeChanged: (range) =>
                    setState(() => _selectedTimeRange = range),
              ),
      ),
    );
  }
}
