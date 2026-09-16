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
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
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
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
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

class _BookingsPageState extends State<BookingsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late SessionTickerNotifier _sessionTickerNotifier;

  // Independent Scroll Controllers
  late ScrollController _mobileScrollController;
  late ScrollController _leftDesktopScrollController;
  late ScrollController _rightDesktopScrollController;

  int _selectedTabIndex = 0;
  bool _isOccupancyExpanded = true;
  bool _isFinishedTableView = true; // Toggle for Finished tab: Table vs Cards

  BookingFilterState _filterState = const BookingFilterState();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _sessionTickerNotifier = SessionTickerNotifier();

    _mobileScrollController = ScrollController();
    _leftDesktopScrollController = ScrollController();
    _rightDesktopScrollController = ScrollController();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
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
    }
    await context.read<LoungeCubit>().fetchLounges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sessionTickerNotifier.dispose();

    _mobileScrollController.dispose();
    _leftDesktopScrollController.dispose();
    _rightDesktopScrollController.dispose();

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

      if (_filterState.selectedRoomId != null) {
        if (b.roomId != _filterState.selectedRoomId) return false;
      }

      if (_filterState.selectedStatus != null) {
        if (b.status != _filterState.selectedStatus) return false;
      }

      if (_filterState.selectedTimeFilter == 'current_shift') {
        if (!BookingState.isBookingInCurrentShiftOrToday(b, activeShift)) return false;
      } else if (_filterState.selectedTimeFilter == 'morning') {
        if (b.date.hour >= 16) return false;
      } else if (_filterState.selectedTimeFilter == 'evening') {
        if (b.date.hour < 16) return false;
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
      builder: (_) => AddBookingDialog(
        loungeId: loungeId,
      ),
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
                      const Expanded(
                        child: RepaintBoundary(child: LiveRequestsFeed()),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        floatingActionButton: !isDesktop
            ? FloatingActionButton.extended(
                backgroundColor: AppColors.neonBlue,
                icon: const Icon(Icons.add, color: Colors.black),
                label: Text(
                  AppStrings.newBooking,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
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
                listener: (context, state) {
                  final updatedLoungeId = state.user?.loungeId;
                  _initRealtimeStreams(updatedLoungeId);
                },
              ),
              BlocListener<BookingCubit, BookingState>(
                listenWhen: (previous, current) => previous.status != current.status,
                listener: (context, state) {
                  if (state.status == BookingStatusState.failure) {
                    final errMsg = state.errorMessage ?? AppStrings.actionFailed;
                    final isShiftError = errMsg.contains('وردية') || errMsg.toLowerCase().contains('shift');

                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.white),
                            SizedBox(width: 8.w),
                            Expanded(child: Text(errMsg)),
                          ],
                        ),
                        backgroundColor: AppColors.danger,
                        duration: Duration(seconds: isShiftError ? 10 : 4),
                        action: isShiftError ? SnackBarAction(
                          label: AppStrings.quickOpenShiftInstant,
                          textColor: Colors.yellow,
                          onPressed: () async {
                            final currentLoungeId = context.read<LoginCubit>().state.user?.loungeId;
                            if (currentLoungeId != null) {
                              final success = await context.read<ShiftCubit>().quickOpenShift(currentLoungeId, 0.0);
                              if (context.mounted && success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                                        SizedBox(width: 8.w),
                                        Text(AppStrings.shiftOpenedSuccessMsg),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                          },
                        ) : null,
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
              child: isDesktop
                  ? _buildDesktopTwoColumnLayout(context, loungeId, userLounge)
                  : _buildMobileSingleScrollLayout(context, loungeId, userLounge, unreadRequestsCount),
            ),
          ),
        ),
      ),
    );
  }

  /// Desktop Layout: Two side-by-side columns, each with its own CustomScrollView & ScrollController!
  Widget _buildDesktopTwoColumnLayout(BuildContext context, String loungeId, dynamic userLounge) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: CustomScrollView(
            controller: _leftDesktopScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: ShiftHeaderBanner()),
              SliverToBoxAdapter(child: SizedBox(height: 12.h)),
              _buildCollapsibleOccupancyGrid(loungeId),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: RepaintBoundary(child: _buildLiveStatsHeader(context, userLounge))),
                    SizedBox(width: 12.w),
                    _buildQuickActionButtons(context, loungeId),
                  ],
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
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              PinnedHeaderSliver(
                child: Container(
                  color: AppColors.scaffoldBackground,
                  child: _buildTabsWithBadges(context, userLounge),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              ..._buildActiveTabSlivers(context, userLounge),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 3,
          child: CustomScrollView(
            controller: _rightDesktopScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: const [
              SliverToBoxAdapter(
                child: RepaintBoundary(child: LiveRequestsFeed()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mobile Layout: Single Scroll Axis with drawer button for Live Requests Feed
  Widget _buildMobileSingleScrollLayout(BuildContext context, String loungeId, dynamic userLounge, int unreadRequestsCount) {
    return CustomScrollView(
      controller: _mobileScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: ShiftHeaderBanner()),
        SliverToBoxAdapter(child: SizedBox(height: 12.h)),
        SliverToBoxAdapter(
          child: Builder(
            builder: (scaffoldContext) => InkWell(
              onTap: () => Scaffold.of(scaffoldContext).openEndDrawer(),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 20.r),
                        SizedBox(width: 8.w),
                        AppText.subHeading(AppStrings.clientRequestsAndAlerts, fontSize: 13.sp),
                      ],
                    ),
                    if (unreadRequestsCount > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          AppStrings.newRequestsCount('$unreadRequestsCount'),
                          style: TextStyle(color: Colors.black, fontSize: 10.sp, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14.r),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 12.h)),
        _buildCollapsibleOccupancyGrid(loungeId),
        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
        SliverToBoxAdapter(
          child: RepaintBoundary(child: _buildLiveStatsHeader(context, userLounge)),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
        SliverToBoxAdapter(
          child: BookingFilterBar(
            filterState: _filterState,
            onFilterChanged: (newState) => setState(() => _filterState = newState),
            onResetFilters: () => setState(() => _filterState = const BookingFilterState()),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
        PinnedHeaderSliver(
          child: Container(
            color: AppColors.scaffoldBackground,
            child: _buildTabsWithBadges(context, userLounge),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
        ..._buildActiveTabSlivers(context, userLounge),
      ],
    );
  }

  Widget _buildCollapsibleOccupancyGrid(String loungeId) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _isOccupancyExpanded = !_isOccupancyExpanded),
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.map_rounded, color: AppColors.neonBlue, size: 18.r),
                        SizedBox(width: 8.w),
                        AppText.subHeading(AppStrings.devicesAndRoomsMap, fontSize: 14.sp),
                      ],
                    ),
                    Icon(
                      _isOccupancyExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: 20.r,
                    ),
                  ],
                ),
              ),
            ),
            if (_isOccupancyExpanded) ...[
              const Divider(color: AppColors.borderDefault, height: 1),
              Padding(
                padding: EdgeInsets.all(12.r),
                child: RepaintBoundary(child: RoomOccupancyGrid(loungeId: loungeId)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context, String loungeId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocSelector<BookingCubit, BookingState, BookingStatusState>(
          selector: (state) => state.status,
          builder: (context, status) {
            final bool isLoading = status == BookingStatusState.loading;

            return MouseRegion(
              cursor: isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
              child: InkWell(
                onTap: isLoading ? null : _handleRefresh,
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 18.r,
                          height: 18.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.neonBlue,
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          color: AppColors.neonBlue,
                          size: 20.r,
                        ),
                ),
              ),
            );
          },
        ),
        SizedBox(width: 10.w),
        AppButton(
          text: AppStrings.newBooking,
          icon: Icons.add,
          variant: AppButtonVariant.primary,
          height: 38.h,
          onPressed: () => _showAddBookingModal(context, loungeId),
        ),
      ],
    );
  }

  Widget _buildTabsWithBadges(BuildContext context, dynamic userLounge) {
    final bookingState = context.watch<BookingCubit>().state;
    final shiftState = context.watch<ShiftCubit>().state;
    final activeShift = shiftState.activeShift;

    final activeCount = bookingState.activeBookings.length;
    final pendingCount = bookingState.pendingBookings.length;
    final finishedCount = bookingState.currentShiftBookings(activeShift: activeShift, userLounge: userLounge).length;

    final bool isMobileScreen = MediaQuery.sizeOf(context).width < 500;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: isMobileScreen,
        tabAlignment: isMobileScreen ? TabAlignment.start : TabAlignment.fill,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: AppColors.neonBlue.withValues(alpha: 0.1),
        ),
        labelColor: AppColors.neonBlue,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppStrings.activeBookings),
                if (activeCount > 0) ...[
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.neonBlue,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '$activeCount',
                      style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppStrings.pendingRequests),
                if (pendingCount > 0) ...[
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: TextStyle(color: Colors.black, fontSize: 10.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppStrings.finishedToday),
                if (finishedCount > 0) ...[
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.mutedBackground,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '$finishedCount',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActiveTabSlivers(BuildContext context, dynamic userLounge) {
    final bookingState = context.watch<BookingCubit>().state;
    final shiftState = context.watch<ShiftCubit>().state;
    final activeShift = shiftState.activeShift;

    if (bookingState.status == BookingStatusState.loading && bookingState.bookings.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: GridShimmer(itemCount: 4, aspectRatio: 1.2),
        ),
      ];
    }

    final List<Booking> rawList;
    if (_selectedTabIndex == 0) {
      rawList = bookingState.activeBookings;
    } else if (_selectedTabIndex == 1) {
      rawList = bookingState.pendingBookings;
    } else {
      rawList = bookingState.currentShiftBookings(activeShift: activeShift, userLounge: userLounge);
    }

    final filteredBookings = _applyFilters(rawList, activeShift);

    if (filteredBookings.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Center(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 40.r, color: AppColors.textMuted),
                  SizedBox(height: 8.h),
                  AppText.body(
                    _selectedTabIndex == 0
                        ? AppStrings.noActiveBookings
                        : (_selectedTabIndex == 1 ? AppStrings.noNewRequests : AppStrings.noFinishedBookings),
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                  SizedBox(height: 10.h),
                  AppButton(
                    text: AppStrings.refresh,
                    variant: AppButtonVariant.outlined,
                    height: 32.h,
                    onPressed: _handleRefresh,
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    if (_selectedTabIndex == 2) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.subHeading(AppStrings.finishedBookingsHistoryToday, fontSize: 13.sp),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.table_chart_rounded,
                        color: _isFinishedTableView ? AppColors.neonBlue : AppColors.textMuted,
                        size: 20.r,
                      ),
                      tooltip: AppStrings.showAsTable,
                      onPressed: () => setState(() => _isFinishedTableView = true),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.grid_view_rounded,
                        color: !_isFinishedTableView ? AppColors.neonBlue : AppColors.textMuted,
                        size: 20.r,
                      ),
                      tooltip: AppStrings.showAsCards,
                      onPressed: () => setState(() => _isFinishedTableView = false),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_isFinishedTableView)
          SliverToBoxAdapter(
            child: RepaintBoundary(
              child: _buildFinishedDataTable(context, filteredBookings),
            ),
          )
        else
          _buildSliverBookingGrid(context, filteredBookings, isPending: false, isAudit: true),
      ];
    }

    return [
      _buildSliverBookingGrid(
        context,
        filteredBookings,
        isPending: _selectedTabIndex == 1,
        isAudit: false,
      ),
    ];
  }

  Widget _buildSliverBookingGrid(
    BuildContext context,
    List<Booking> bookings, {
    required bool isPending,
    bool isAudit = false,
  }) {
    final cubit = context.read<BookingCubit>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final double maxExtent = screenWidth < 600 ? double.infinity : (screenWidth < 1024 ? 360.w : 400.w);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxExtent,
        mainAxisExtent: 275.h,
        crossAxisSpacing: 14.r,
        mainAxisSpacing: 14.r,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final booking = bookings[index];
          if (booking.status == BookingStatus.inProgress) {
            return LiveSessionCard(
              key: ValueKey('live_session_${booking.id}'),
              booking: booking,
              width: double.infinity,
            );
          }
          final isBookingPending = booking.status == BookingStatus.pending;
          return BookingCard(
            key: ValueKey('booking_${booking.id}'),
            booking: booking,
            width: double.infinity,
            onApprove: isBookingPending ? () => cubit.approveBooking(booking.id) : null,
            onReject: isBookingPending ? () => cubit.rejectBooking(booking.id) : null,
            onConfirmPayment: !isBookingPending && !isAudit && booking.paymentStatus != PaymentStatus.paid
                ? () => _showBookingDetails(context, booking)
                : null,
          );
        },
        childCount: bookings.length,
      ),
    );
  }

  Widget _buildFinishedDataTable(BuildContext context, List<Booking> bookings) {
    final columns = [
      AppStrings.customer,
      AppStrings.roomLabel,
      AppStrings.time,
      AppStrings.amount,
      AppStrings.paymentMethod,
      AppStrings.actions,
    ];

    final rows = bookings.map((b) {
      final isPaid = b.paymentStatus == PaymentStatus.paid;
      return DataRow(
        cells: [
          DataCell(
            Text(
              b.userName ?? AppStrings.anonymous,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w500),
            ),
          ),
          DataCell(
            Text(
              b.roomName.isNotEmpty ? b.roomName : AppStrings.roomLabel,
              style: TextStyle(color: AppColors.neonPurple, fontSize: 13.sp),
            ),
          ),
          DataCell(
            Text(
              b.startTime,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
            ),
          ),
          DataCell(
            Text(
              '${b.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}',
              style: TextStyle(color: AppColors.neonGreen, fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(
            isPaid
                ? StatusBadge.success(AppStrings.paid.toUpperCase())
                : StatusBadge.warning(AppStrings.unpaid.toUpperCase()),
          ),
          DataCell(
            IconButton(
              icon: Icon(Icons.info_outline_rounded, color: AppColors.neonBlue, size: 18.r),
              onPressed: () => _showBookingDetails(context, b),
            ),
          ),
        ],
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - 32.w),
        child: DataTableWidget(
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }

  Widget _buildLiveStatsHeader(BuildContext context, dynamic userLounge) {
    final bookingState = context.watch<BookingCubit>().state;
    final shiftState = context.watch<ShiftCubit>().state;
    final activeShift = shiftState.activeShift;

    final activeCount = bookingState.activeBookings.length;
    final pendingCount = bookingState.pendingBookings.length;
    final totalRevenue = bookingState.currentShiftRevenue(activeShift: activeShift, userLounge: userLounge);

    return Responsive(
      mobile: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            const LiveIndicatorBadge(),
            SizedBox(width: 8.w),
            _buildMiniStatCard(AppStrings.activeSessions, activeCount.toString(), AppColors.neonBlue, Icons.sports_esports),
            SizedBox(width: 8.w),
            _buildMiniStatCard(AppStrings.pendingRequests, pendingCount.toString(), AppColors.warning, Icons.notification_important),
            SizedBox(width: 8.w),
            _buildMiniStatCard(AppStrings.dailyTotal, "${totalRevenue.toStringAsFixed(0)} ${AppStrings.egp}", AppColors.success, Icons.account_balance_wallet),
          ],
        ),
      ),
      tablet: Row(
        children: [
          const LiveIndicatorBadge(),
          SizedBox(width: 8.w),
          Expanded(child: _buildMiniStatCard(AppStrings.activeSessions, activeCount.toString(), AppColors.neonBlue, Icons.sports_esports)),
          SizedBox(width: 8.w),
          Expanded(child: _buildMiniStatCard(AppStrings.pendingRequests, pendingCount.toString(), AppColors.warning, Icons.notification_important)),
          SizedBox(width: 8.w),
          Expanded(child: _buildMiniStatCard(AppStrings.dailyTotal, "${totalRevenue.toStringAsFixed(0)} ${AppStrings.egp}", AppColors.success, Icons.account_balance_wallet)),
        ],
      ),
      desktop: Row(
        children: [
          const LiveIndicatorBadge(),
          SizedBox(width: 12.w),
          Expanded(child: _buildMiniStatCard(AppStrings.activeSessions, activeCount.toString(), AppColors.neonBlue, Icons.sports_esports)),
          SizedBox(width: 12.w),
          Expanded(child: _buildMiniStatCard(AppStrings.pendingRequests, pendingCount.toString(), AppColors.warning, Icons.notification_important)),
          SizedBox(width: 12.w),
          Expanded(child: _buildMiniStatCard(AppStrings.dailyTotal, "${totalRevenue.toStringAsFixed(0)} ${AppStrings.egp}", AppColors.success, Icons.account_balance_wallet)),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: color, size: 16.r),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.body(label, color: AppColors.textSecondary, fontSize: 10.sp, maxLines: 1),
                SizedBox(height: 1.h),
                AppText.subHeading(value, color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.bold, maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
