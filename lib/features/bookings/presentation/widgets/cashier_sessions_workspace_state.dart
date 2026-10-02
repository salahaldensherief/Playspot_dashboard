part of 'cashier_sessions_workspace.dart';

class _CashierSessionsWorkspaceState extends State<CashierSessionsWorkspace> {
  String? _selectedId;
  final _revision = ValueNotifier<int>(0);
  late final Timer _classificationTimer;
  late final DateTime Function() _clock;
  List<Booking> _ordered = const [];
  ModalRoute<void>? _sheetRoute;
  Future<void>? _sheetOpening;

  void _classify() {
    _ordered = _computeOrder();
    if (_ordered.isNotEmpty &&
        !_ordered.any((booking) => booking.id == _selectedId)) {
      _selectedId = _ordered.first.id;
    }
  }

  List<Booking> _computeOrder() {
    final groups = LiveSessionsOperationsGroups.fromBookings(
      widget.bookings,
      now: _clock(),
    );
    return [
      ...groups.needsAttention,
      ...groups.openTime,
      ...groups.running,
      ...groups.upcoming,
    ];
  }

  void _refreshClassification() {
    if (!mounted) return;
    final ordered = _computeOrder();
    if (!listEquals(_ordered, ordered)) setState(() => _ordered = ordered);
  }

  @override
  void initState() {
    super.initState();
    _clock = SessionTickerScope.clockOf(context);
    _classify();
    _classificationTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshClassification(),
    );
  }

  @override
  void didUpdateWidget(CashierSessionsWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    _classify();
    if (oldWidget.bookings != widget.bookings ||
        oldWidget.requests != widget.requests) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revision.value++;
      });
    }
  }

  @override
  void dispose() {
    _closeOwnedSheet();
    _classificationTimer.cancel();
    _revision.dispose();
    super.dispose();
  }

  List<ClientRequestEntity> _requestsFor(Booking booking) => widget.requests
      .where(
        (request) =>
            request.loungeId == booking.loungeId &&
            !request.isAttended &&
            (request.bookingId == booking.id ||
                (request.bookingId == null &&
                    request.roomId == booking.roomId)),
      )
      .toList();

  Widget _details(Booking booking) => CashierSessionDetails(
    summary: SessionOperationsSummary.fromBookings(booking, widget.bookings),
    requests: _requestsFor(booking),
    onManage: () => widget.onManage(booking),
  );

  void _select(Booking booking, bool mobile) {
    setState(() => _selectedId = booking.id);
    if (!mobile || _sheetOpening != null) return;
    _sheetOpening =
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (sheetContext) => _sheetContents(sheetContext, booking),
        ).whenComplete(() {
          _sheetRoute = null;
          _sheetOpening = null;
        });
  }

  Widget _sheetContents(BuildContext sheetContext, Booking booking) {
    _sheetRoute = ModalRoute.of(sheetContext);
    if (!mounted) {
      _closeOwnedSheet();
      return const SizedBox.shrink();
    }
    return SessionClockHost(
      clock: _clock,
      child: CashierSessionSheet(
        revision: _revision,
        details: () => _currentSheetDetails(booking),
      ),
    );
  }

  Widget _currentSheetDetails(Booking booking) {
    if (!mounted) return const SizedBox.shrink();
    final current = widget.bookings.where(
      (item) =>
          item.id == booking.id &&
          item.loungeId == booking.loungeId &&
          (item.status == BookingStatus.inProgress ||
              item.status == BookingStatus.upcoming),
    );
    return current.isEmpty
        ? Text('cashier.empty'.tr())
        : _details(current.first);
  }

  void _closeOwnedSheet() {
    final route = _sheetRoute;
    final navigator = route?.navigator;
    if (route == null || navigator == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted && route.isActive) navigator.removeRoute(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = _ordered;
    if (active.isEmpty) return Text('cashier.empty'.tr());
    final matching = active.where((b) => b.id == _selectedId);
    final selected = matching.isEmpty ? active.first : matching.first;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final mobile = AppBreakpoints.isMobileWidth(width);
        if (width <= 0) return const SizedBox.shrink();
        final rail = CashierSessionRail(
          bookings: active,
          selectedId: selected.id,
          isCompact: mobile,
          onSelect: (booking) => _select(booking, mobile),
        );
        if (mobile) return rail;
        return CashierSessionsSplitView(
          rail: rail,
          sessionId: selected.id,
          details: _details(selected),
        );
      },
    );
  }
}
