part of 'session_control_actions.dart';

class _SessionControlActionsState extends State<SessionControlActions> {
  bool _busy = false;
  bool _confirming = false;
  String? _error;

  bool _allowed(String capability) {
    if (context.read<LoginCubit?>() == null ||
        context.read<PermissionsCubit?>() == null)
      return false;
    return context.hasPermission(capability);
  }

  Future<void> _run(Future<bool> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bookings = context.read<BookingCubit>();
      final loungeId = widget.booking.loungeId;
      final success = await action();
      if (success && mounted)
        bookings.startWatchingBookings(loungeId: loungeId, forceRefresh: true);
      if (mounted)
        setState(() => _error = success ? null : 'cashier.actionFailed'.tr());
    } catch (_) {
      if (mounted) setState(() => _error = 'cashier.actionFailed'.tr());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end() async {
    if (_busy || _confirming || !_allowed('sessions_control')) return;
    final booking = widget.booking;
    _confirming = true;
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'cashier.end'.tr(),
      message: 'cashier.endConfirm'.tr(),
    );
    _confirming = false;
    if (!mounted || confirmed != true || !_allowed('sessions_control')) return;
    await _run(() async {
      if (booking.isOpenEnded) {
        final result = await context
            .read<BookingCubit>()
            .completeOpenTimeSession(booking.id);
        return result != null && result['final_total'] != null;
      }
      return context.read<DashboardCubit>().endSession(booking.id);
    });
  }

  Future<void> _collect() async {
    if (_busy || _confirming || !_allowed('billing_checkout')) return;
    final booking = widget.booking;
    _confirming = true;
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'cashier.collect'.tr(),
      message: 'cashier.collectConfirm'.tr(),
    );
    _confirming = false;
    if (!mounted || confirmed != true || !_allowed('billing_checkout')) return;
    await _run(
      () => context.read<BookingCubit>().confirmCashPayment(booking.id),
    );
  }

  Future<void> _extend(int minutes) async {
    if (_busy || _confirming || !_allowed('sessions_control')) return;
    final booking = widget.booking;
    await _run(
      () => context.read<DashboardCubit>().extendSession(booking.id, minutes),
    );
  }

  Widget _extensions(Booking booking) => Wrap(
    spacing: OperationsTokens.gap,
    runSpacing: OperationsTokens.gap,
    children: [
      for (final minutes in [15, 30, 60])
        AppButton(
          text: '+$minutes ${'cashier.minutes'.tr()}',
          height: 48,
          width: 96,
          isLoading: _busy,
          onPressed: !_busy && _allowed('sessions_control')
              ? () => _extend(minutes)
              : null,
        ),
    ],
  );
  Widget _endButton() => AppButton(
    text: 'cashier.end'.tr(),
    height: 48,
    isLoading: _busy,
    variant: AppButtonVariant.danger,
    onPressed: !_busy && _allowed('sessions_control') ? _end : null,
  );
  Widget _collectButton() => AppButton(
    text: 'cashier.collect'.tr(),
    height: 48,
    isLoading: _busy,
    onPressed: !_busy && _allowed('billing_checkout') ? _collect : null,
  );
  Widget _swapButton(Booking booking) => AppButton(
    text: 'cashier.swap'.tr(),
    height: 48,
    variant: AppButtonVariant.outlined,
    onPressed: !_busy && _allowed('rooms_manage')
        ? () => showDialog<void>(
            context: context,
            builder: (_) => SwapRoomDialog(
              bookingId: booking.id,
              currentRoomId: booking.roomId,
            ),
          )
        : null,
  );
  @override
  Widget build(BuildContext context) {
    context.select((PermissionsCubit? cubit) => cubit?.state);
    context.select((LoginCubit? cubit) => cubit?.state.user);
    final booking = widget.booking;
    final running = booking.status == BookingStatus.inProgress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) Text(_error ?? '', style: OperationsTokens.value),
        if (running && !booking.isOpenEnded) _extensions(booking),
        if (running) ...[
          const SizedBox(height: OperationsTokens.gap),
          _endButton(),
        ],
        if (booking.paymentStatus != PaymentStatus.paid &&
            (!booking.isOpenEnded || !running)) ...[
          const SizedBox(height: OperationsTokens.gap),
          _collectButton(),
        ],
        if (running) ...[
          const SizedBox(height: OperationsTokens.gap),
          _swapButton(booking),
        ],
        const SizedBox(height: OperationsTokens.gap),
        Text('cashier.permissionNotice'.tr(), style: OperationsTokens.label),
      ],
    );
  }
}
