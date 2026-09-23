import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/core/responsive/app_breakpoints.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_details_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_filter_bar.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/bookings_active_grid.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/bookings_cockpit_stats_bar.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/bookings_cockpit_tabs.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/bookings_collapsible_occupancy.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/bookings_requests_sidebar.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_ticker.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/extras_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/widgets/lounge_discount_banner.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/domain/entities/shift_entity.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/shift_header_banner.dart';

/// Redesigned Modern & Immersive Web Bookings & Live Sessions Page
class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SessionTickerNotifier _sessionTickerNotifier;
  late ScrollController _mainScrollController;

  int _selectedTabIndex = 0;
  bool _isTableView = false;

  BookingFilterState _filterState = const BookingFilterState();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _sessionTickerNotifier = SessionTickerNotifier();
    _mainScrollController = ScrollController();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<LoginCubit>().state.user;
      final loungeId = user?.loungeId;
      _initRealtimeStreams(loungeId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sessionTickerNotifier.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  void _initRealtimeStreams(String? loungeId) {
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;

    context.read<BookingCubit>().startWatchingBookings(loungeId: cleanLoungeId);
    if (cleanLoungeId != null) {
      context.read<ClientRequestsCubit>().startWatchingRequests(loungeId: cleanLoungeId);
      context.read<RoomCubit>().watchRooms(cleanLoungeId);
      context.read<ExtrasCubit>().loadExtras(cleanLoungeId);
    }
    context.read<LoungeCubit>().fetchLounges();
  }

  Future<void> _handleRefresh() async {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId;
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;

    context.read<BookingCubit>().startWatchingBookings(loungeId: cleanLoungeId, forceRefresh: true);
    if (cleanLoungeId != null) {
      context.read<ClientRequestsCubit>().startWatchingRequests(loungeId: cleanLoungeId, forceRefresh: true);
      context.read<RoomCubit>().watchRooms(cleanLoungeId, forceRefresh: true);
      context.read<ExtrasCubit>().loadExtras(cleanLoungeId, forceRefresh: true);
    }
    await context.read<LoungeCubit>().fetchLounges();
  }

  List<Booking> _applyFilters(List<Booking> raw, ShiftEntity? activeShift) {
    return raw.where((b) {
      if (_filterState.searchQuery.isNotEmpty) {
        final q = _filterState.searchQuery.toLowerCase().trim();
        final nameMatch = (b.userName ?? '').toLowerCase().contains(q);
        final phoneMatch = (b.userPhone ?? '').contains(q);
        final roomMatch = b.roomName.toLowerCase().contains(q);
        final idMatch = b.id.toLowerCase().contains(q);
        if (!nameMatch && !phoneMatch && !roomMatch && !idMatch) return false;
      }
      if (_filterState.selectedRoomId != null && b.roomId != _filterState.selectedRoomId) {
        return false;
      }
      if (_filterState.selectedStatus != null && b.status != _filterState.selectedStatus) {
        return false;
      }
      if (_filterState.selectedTimeFilter == 'current_shift') {
        if (!BookingState.isBookingInCurrentShiftOrToday(b, activeShift)) return false;
      } else if (_filterState.selectedTimeFilter == 'morning' && b.date.hour >= 16) {
        return false;
      } else if (_filterState.selectedTimeFilter == 'evening' && b.date.hour < 16) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    final shiftState = context.read<ShiftCubit>().state;
    final activeShiftId = shiftState.activeShift?.id;
    final cubit = context.read<BookingCubit>();

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => BookingDetailsDialog(
        booking: booking,
        onConfirmPayment: (amount, percent, reason) {
          cubit.confirmCashPayment(
            booking.id,
            shiftId: activeShiftId,
            discountAmount: amount,
            discountPercentage: percent,
            discountReason: reason,
          );
        },
        onCancel: () => cubit.rejectBooking(booking.id),
      ),
    );
  }

  void _showAddBookingModal(BuildContext context, String loungeId) {
    context.read<RoomCubit>().watchRooms(loungeId);
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => AddBookingDialog(loungeId: loungeId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = context.watch<LoginCubit>().state;
    final user = loginState.user;
    final loungeId = user?.loungeId ?? '';
    final userLounge = loginState.userLounge;
    final isDesktop = AppBreakpoints.isDesktop(context);

    return SessionTickerScope(
      ticker: _sessionTickerNotifier,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        endDrawer: !isDesktop
            ? BookingsRequestsSidebar(
                isDrawer: true,
                onCloseDrawer: () => Navigator.of(context).pop(),
              )
            : null,
        body: DashboardLayout(
          title: AppStrings.bookings,
          activeRoute: 'Bookings',
          isScrollable: false,
          child: MultiBlocListener(
            listeners: [
              BlocListener<LoginCubit, LoginState>(
                listenWhen: (previous, current) => previous.user?.loungeId != current.user?.loungeId,
                listener: (context, state) => _initRealtimeStreams(state.user?.loungeId),
              ),
              BlocListener<BookingCubit, BookingState>(
                listenWhen: (previous, current) => previous.status != current.status,
                listener: (context, state) {
                  if (state.status == BookingStatusState.failure) {
                    final errMsg = state.errorMessage ?? AppStrings.actionFailed;
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errMsg), backgroundColor: AppColors.danger),
                    );
                  }
                },
              ),
            ],
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.neonBlue,
              backgroundColor: AppColors.cardBackground,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Operations Workspace
                  Expanded(
                    flex: 7,
                    child: CustomScrollView(
                      controller: _mainScrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: LoungeDiscountBanner(lounge: userLounge)),
                        const SliverToBoxAdapter(child: ShiftHeaderBanner()),
                        SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                        SliverToBoxAdapter(
                          child: BookingsCockpitStatsBar(
                            loungeId: loungeId,
                            userLounge: userLounge,
                            onNewBooking: () => _showAddBookingModal(context, loungeId),
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: 14.h)),
                        SliverToBoxAdapter(
                          child: BookingsCollapsibleOccupancy(
                            loungeId: loungeId,
                            initialExpanded: !AppBreakpoints.isMobile(context),
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                        SliverToBoxAdapter(
                          child: BookingFilterBar(
                            filterState: _filterState,
                            onFilterChanged: (newState) => setState(() => _filterState = newState),
                            onResetFilters: () => setState(() => _filterState = const BookingFilterState()),
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: 14.h)),
                        SliverToBoxAdapter(
                          child: Container(
                            color: AppColors.scaffoldBackground,
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: BookingsCockpitTabs(
                              tabController: _tabController,
                              userLounge: userLounge,
                              isDesktop: isDesktop,
                              isTableView: _isTableView,
                              onToggleTableView: () => setState(() => _isTableView = !_isTableView),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: 14.h)),
                        ..._buildActiveBookingsView(context, userLounge),
                        SliverToBoxAdapter(child: SizedBox(height: 40.h)),
                      ],
                    ),
                  ),

                  // Desktop Realtime Sidebar
                  if (isDesktop) ...[
                    SizedBox(width: 16.w),
                    const Expanded(
                      flex: 3,
                      child: BookingsRequestsSidebar(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActiveBookingsView(BuildContext context, dynamic userLounge) {
    return [
      BlocBuilder<BookingCubit, BookingState>(
        buildWhen: (prev, curr) => prev.bookings != curr.bookings || prev.status != curr.status,
        builder: (context, bookingState) {
          return BlocBuilder<ShiftCubit, ShiftState>(
            buildWhen: (prev, curr) => prev.activeShift != curr.activeShift,
            builder: (context, shiftState) {
              final activeShift = shiftState.activeShift;

              if (bookingState.status == BookingStatusState.loading && bookingState.bookings.isEmpty) {
                return const GridShimmer(itemCount: 4, aspectRatio: 1.3);
              }

              final List<Booking> list = _selectedTabIndex == 0
                  ? bookingState.activeBookings
                  : (_selectedTabIndex == 1
                      ? bookingState.pendingBookings
                      : bookingState.currentShiftBookings(activeShift: activeShift, userLounge: userLounge));

              final filtered = _applyFilters(list, activeShift);

              return BookingsActiveGrid(
                bookings: filtered,
                isTableView: _isTableView,
                onShowDetails: (b) => _showBookingDetails(context, b),
                onApprove: (id) => context.read<BookingCubit>().approveBooking(id),
                onReject: (id) => context.read<BookingCubit>().rejectBooking(id),
              );
            },
          );
        },
      ),
    ];
  }
}
