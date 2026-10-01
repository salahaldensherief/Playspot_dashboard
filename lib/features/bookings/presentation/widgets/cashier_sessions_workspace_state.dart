part of 'cashier_sessions_workspace.dart';

class _CashierSessionsWorkspaceState extends State<CashierSessionsWorkspace> {
  String? _selectedId;
  final _revision = ValueNotifier<int>(0);
  late final Timer _classificationTimer;
  List<Booking> _ordered = const [];

  void _classify() {
    final groups = LiveSessionsOperationsGroups.fromBookings(widget.bookings);
    _ordered = [
      ...groups.needsAttention,
      ...groups.openTime,
      ...groups.running,
      ...groups.upcoming,
    ];
  }

  @override
  void initState() {
    super.initState();
    _classify();
    _classificationTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(_classify);
    });
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
    _classificationTimer.cancel();
    _revision.dispose();
    super.dispose();
  }

  List<ClientRequestEntity> _requestsFor(Booking booking) => widget.requests
      .where(
        (request) =>
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
    if (!mobile) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SessionClockHost(
        clock: SessionTickerScope.clockOf(context),
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height,
          child: Column(
            children: [
              AppButton(
                text: 'cashier.back'.tr(),
                height: 48,
                variant: AppButtonVariant.text,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: _revision,
                  builder: (_, revision, child) {
                    final current = widget.bookings.where(
                      (item) =>
                          item.id == booking.id &&
                          (item.status == BookingStatus.inProgress ||
                              item.status == BookingStatus.upcoming),
                    );
                    return SingleChildScrollView(
                      child: current.isEmpty
                          ? Text('cashier.empty'.tr())
                          : _details(current.first),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        final rail = ListView.separated(
          shrinkWrap: mobile,
          physics: mobile ? const NeverScrollableScrollPhysics() : null,
          itemCount: active.length,
          separatorBuilder: (_, index) => const Divider(height: 1),
          itemBuilder: (_, index) => CashierSessionTile(
            key: ValueKey(active[index].id),
            booking: active[index],
            selected: selected.id == active[index].id,
            onSelect: () => _select(active[index], mobile),
          ),
        );
        if (mobile) return rail;
        final railWidth = AppBreakpoints.isDesktopWidth(width)
            ? OperationsTokens.railWidth
            : width * 0.4;
        return SizedBox(
          height: OperationsTokens.panelHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: railWidth, child: rail),
              const SizedBox(width: OperationsTokens.gap),
              Expanded(
                child: RepaintBoundary(
                  child: SingleChildScrollView(
                    key: ValueKey(selected.id),
                    child: _details(selected),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
