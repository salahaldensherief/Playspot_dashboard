part of 'session_request_actions.dart';

class _SessionRequestActionsState extends State<SessionRequestActions> {
  bool _busy = false;
  String? _error;
  bool get _allowed {
    if (context.read<LoginCubit?>() == null ||
        context.read<PermissionsCubit?>() == null)
      return false;
    return context.hasPermission('sessions_control');
  }

  Future<void> _attend() async {
    if (_busy || !_allowed) return;
    final cubit = context.read<ClientRequestsCubit>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await cubit.markAsAttended(
        widget.request.id,
        isCanteenOrder: widget.request.isCanteenOrder,
      );
      if (mounted && cubit.state.status == ClientRequestsStatus.failure) {
        setState(() => _error = 'cashier.actionFailed'.tr());
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'cashier.actionFailed'.tr());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    context.select((PermissionsCubit? cubit) => cubit?.state);
    context.select((LoginCubit? cubit) => cubit?.state.user);
    return Padding(
      padding: const EdgeInsets.only(bottom: OperationsTokens.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) Text(_error ?? ''),
          AppButton(
            text: 'cashier.requestDone'.tr(),
            height: 48,
            isLoading: _busy,
            onPressed: !_busy && _allowed ? _attend : null,
          ),
        ],
      ),
    );
  }
}
