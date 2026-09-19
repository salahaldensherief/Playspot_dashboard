import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/live_indicator_badge.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/core/responsive/app_breakpoints.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_card.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_details_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_filter_bar.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/live_session_card.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_occupancy_grid.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_ticker.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/extras_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/widgets/lounge_discount_banner.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/live_requests_feed.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/shift_header_banner.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SessionTickerNotifier _sessionTickerNotifier;

  late ScrollController _mainScrollController;
  late ScrollController _requestsScrollController;

  int _selectedTabIndex = 0;
  bool _isOccupancyExpanded = true;
  bool _isTableView = false;

  BookingFilterState _filterState = const BookingFilterState();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _sessionTickerNotifier = SessionTickerNotifier();

    _mainScrollController = ScrollController();
    _requestsScrollController = ScrollController();

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

      if (AppBreakpoints.isMobile(context)) {
        setState(() => _isOccupancyExpanded = false);
      }
    });
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

  @override
  void dispose() {
    _tabController.dispose();
    _sessionTickerNotifier.dispose();
    _mainScrollController.dispose();
    _requestsScrollController.dispose();
    super.dispose();
  }

  List<Booking> _applyFilters(List<Booking> bookings, dynamic activeShift) {
    return bookings.where((b) {
      if (_filterState.searchQuery.trim().isNotEmpty) {
        final q = _filterState.searchQuery.trim().toLowerCase();
        final nameMatch = (b.userName ?? '').toLowerCase().contains(q);
        final phoneMatch = (b.userPhone ?? '').toLowerCase().contains(q);
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

    final requestsState = context.watch<ClientRequestsCubit>().state;
    final unreadRequestsCount = requestsState.unreadCount;

    return SessionTickerScope(
      ticker: _sessionTickerNotifier,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        endDrawer: !isDesktop
            ? Drawer(
          backgroundColor: AppColors.cardBackground,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.heading(AppStrings.clientRequestsAndAlerts, fontSize: 16.sp),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.borderDefault),
                const Expanded(child: RepaintBoundary(child: LiveRequestsFeed())),
              ],
            ),
          ),
        )
            : null,
        floatingActionButton: !isDesktop
            ? FloatingActionButton.extended(
          backgroundColor: AppColors.neonBlue,
          icon: const Icon(Icons.add_rounded, color: Colors.black),
          label: Text(AppStrings.newBooking, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          onPressed: () => _showAddBookingModal(context, loungeId),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errMsg),
                        backgroundColor: AppColors.danger,
                      ),
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

                        // Operational Stats Bar
                        SliverToBoxAdapter(child: _buildCockpitStatsBar(context, loungeId, userLounge)),
                        SliverToBoxAdapter(child: SizedBox(height: 14.h)),

                        // Compact Room Radar / Occupancy Grid
                        _buildCollapsibleOccupancyGrid(loungeId),
                        SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                        // Filter & View Mode Controls
                        SliverToBoxAdapter(
                          child: BookingFilterBar(
                            filterState: _filterState,
                            onFilterChanged: (newState) => setState(() => _filterState = newState),
                            onResetFilters: () => setState(() => _filterState = const BookingFilterState()),
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: 14.h)),

                        // Tabs Header
                        PinnedHeaderSliver(
                          child: Container(
                            color: AppColors.scaffoldBackground,
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: _buildCockpitTabs(context, userLounge),
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: 14.h)),

                        // Active Tab Bookings
                        ..._buildActiveBookingsView(context, userLounge),
                      ],
                    ),
                  ),

                  // Desktop Realtime Sidebar
                  if (isDesktop) ...[
                    SizedBox(width: 16.w),
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.bolt_rounded, color: AppColors.warning),
                                      SizedBox(width: 6.w),
                                      AppText.subHeading(AppStrings.clientRequestsAndAlerts, fontSize: 13.sp),
                                    ],
                                  ),
                                  if (unreadRequestsCount > 0)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning,
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                      child: Text(
                                        '$unreadRequestsCount',
                                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11.sp),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Divider(color: AppColors.borderDefault, height: 1),
                            const Expanded(child: RepaintBoundary(child: LiveRequestsFeed())),
                          ],
                        ),
                      ),
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

  /// Cockpit Operations Strip: Compact, high-contrast stats bar with quick-add action
  Widget _buildCockpitStatsBar(BuildContext context, String loungeId, dynamic userLounge) {
    final bookingState = context.watch<BookingCubit>().state;
    final shiftState = context.watch<ShiftCubit>().state;
    final activeShift = shiftState.activeShift;

    final activeCount = bookingState.activeBookings.length;
    final pendingCount = bookingState.pendingBookings.length;
    final totalRevenue = bookingState.currentShiftRevenue(activeShift: activeShift, userLounge: userLounge);

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          const LiveIndicatorBadge(),
          SizedBox(width: 12.w),
          Expanded(
            child: Row(
              children: [
                _buildCockpitItem('الجلسات الجارية', '$activeCount', AppColors.neonBlue, Icons.sports_esports),
                _buildCockpitItem('طلبات بالانتظار', '$pendingCount', AppColors.warning, Icons.access_time_filled),
                _buildCockpitItem('إيراد الوردية', '${totalRevenue.toStringAsFixed(0)} ${AppStrings.egp}', AppColors.neonGreen, Icons.account_balance_wallet),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          AppButton(
            text: AppStrings.newBooking,
            icon: Icons.add_rounded,
            variant: AppButtonVariant.primary,
            height: 38.h,
            onPressed: () => _showAddBookingModal(context, loungeId),
          ),
        ],
      ),
    );
  }

  Widget _buildCockpitItem(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16.r, color: color),
          SizedBox(width: 6.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp)),
              Text(value, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleOccupancyGrid(String loungeId) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _isOccupancyExpanded = !_isOccupancyExpanded),
              borderRadius: BorderRadius.circular(14.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.dashboard_customize_outlined, color: AppColors.neonBlue, size: 18.r),
                        SizedBox(width: 8.w),
                        AppText.subHeading(AppStrings.devicesAndRoomsMap, fontSize: 13.sp),
                      ],
                    ),
                    Icon(
                      _isOccupancyExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (_isOccupancyExpanded) ...[
              const Divider(color: AppColors.borderDefault, height: 1),
              Padding(
                padding: EdgeInsets.all(12.r),
                child: RoomOccupancyGrid(loungeId: loungeId),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCockpitTabs(BuildContext context, dynamic userLounge) {
    final bookingState = context.watch<BookingCubit>().state;
    final shiftState = context.watch<ShiftCubit>().state;
    final activeShift = shiftState.activeShift;

    final activeCount = bookingState.activeBookings.length;
    final pendingCount = bookingState.pendingBookings.length;
    final finishedCount = bookingState.currentShiftBookings(activeShift: activeShift, userLounge: userLounge).length;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: AppColors.neonBlue.withAlpha(35),
              ),
              labelColor: AppColors.neonBlue,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
              tabs: [
                Tab(text: '${AppStrings.activeBookings} ($activeCount)'),
                Tab(text: '${AppStrings.pendingRequests} ($pendingCount)'),
                Tab(text: '${AppStrings.finishedToday} ($finishedCount)'),
              ],
            ),
          ),
        ),
        SizedBox(width: 8.w),
        IconButton(
          tooltip: 'تبديل شكل العرض',
          icon: Icon(_isTableView ? Icons.grid_view_rounded : Icons.view_agenda_outlined, color: AppColors.neonBlue),
          onPressed: () => setState(() => _isTableView = !_isTableView),
        ),
      ],
    );
  }

  List<Widget> _buildActiveBookingsView(BuildContext context, dynamic userLounge) {
    final bookingState = context.watch<BookingCubit>().state;
    final shiftState = context.watch<ShiftCubit>().state;
    final activeShift = shiftState.activeShift;

    if (bookingState.status == BookingStatusState.loading && bookingState.bookings.isEmpty) {
      return [const SliverToBoxAdapter(child: GridShimmer(itemCount: 4, aspectRatio: 1.3))];
    }

    final List<Booking> list = _selectedTabIndex == 0
        ? bookingState.activeBookings
        : (_selectedTabIndex == 1
        ? bookingState.pendingBookings
        : bookingState.currentShiftBookings(activeShift: activeShift, userLounge: userLounge));

    final filtered = _applyFilters(list, activeShift);

    if (filtered.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.all(40.r),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 42.r, color: AppColors.textMuted),
                SizedBox(height: 8.h),
                Text('لا توجد عناصر مطابقة في هذا التبويب', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
              ],
            ),
          ),
        ),
      ];
    }

    if (_isTableView) {
      return [SliverToBoxAdapter(child: _buildFinishedDataTable(context, filtered))];
    }

    return [
      SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 420.w,
          mainAxisExtent: 380.h,
          crossAxisSpacing: 12.r,
          mainAxisSpacing: 12.r,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final b = filtered[index];
            if (b.status == BookingStatus.inProgress) {
              return LiveSessionCard(key: ValueKey('live_${b.id}'), booking: b, width: double.infinity);
            }
            return BookingCard(
              key: ValueKey('booking_${b.id}'),
              booking: b,
              width: double.infinity,
              onApprove: b.status == BookingStatus.pending ? () => context.read<BookingCubit>().approveBooking(b.id) : null,
              onReject: b.status == BookingStatus.pending ? () => context.read<BookingCubit>().rejectBooking(b.id) : null,
              onConfirmPayment: () => _showBookingDetails(context, b),
            );
          },
          childCount: filtered.length,
        ),
      ),
    ];
  }

  Widget _buildFinishedDataTable(BuildContext context, List<Booking> bookings) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: DataTableWidget(
        columns: [
          AppStrings.customer,
          AppStrings.roomLabel,
          AppStrings.time,
          AppStrings.amount,
          AppStrings.paymentMethod,
          AppStrings.actions,
        ],
        rows: bookings.map((b) {
          return DataRow(
            cells: [
              DataCell(Text(b.userName ?? AppStrings.anonymous, style: const TextStyle(color: AppColors.textPrimary))),
              DataCell(Text(b.roomName, style: const TextStyle(color: AppColors.neonPurple))),
              DataCell(Text(b.startTime, style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(Text('${b.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}', style: const TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.bold))),
              DataCell(StatusBadge(
                text: b.paymentStatus == PaymentStatus.paid ? 'مدفوع' : 'غير مدفوع',
                color: b.paymentStatus == PaymentStatus.paid ? AppColors.success : AppColors.warning,
              )),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, color: AppColors.neonBlue),
                  onPressed: () => _showBookingDetails(context, b),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}