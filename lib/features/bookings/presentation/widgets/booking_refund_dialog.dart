import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../core/utils/permission_extension.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/login/login_cubit.dart';
import '../../../permissions/presentation/cubit/permissions_cubit.dart';
import '../../../shifts/presentation/shift_management/shift_cubit.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_refund_repository.dart';
import '../cubit/booking_refund_cubit.dart';

class BookingRefundButton extends StatelessWidget {
  final Booking booking;
  const BookingRefundButton({super.key, required this.booking});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<LoginCubit?>()?.state.user;
    context.watch<PermissionsCubit?>();
    if (!_authorized(context, user, booking.loungeId)) {
      return const SizedBox.shrink();
    }
    return TextButton.icon(
      icon: const Icon(Icons.currency_exchange),
      label: Text(AppStrings.refundManage),
      onPressed: () {
        final login = context.read<LoginCubit>();
        final shifts = context.read<ShiftCubit>();
        final permissions = context.read<PermissionsCubit?>();
        showDialog<void>(
          context: context,
          useRootNavigator: false,
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: login),
              BlocProvider.value(value: shifts),
              if (permissions != null) BlocProvider.value(value: permissions),
              BlocProvider(
                create: (_) => BookingRefundCubit(
                  GetIt.I<BookingRefundRepository>(),
                  booking.id,
                  booking.loungeId,
                )..load(),
              ),
            ],
            child: BookingRefundDialog(booking: booking),
          ),
        );
      },
    );
  }
}

bool _authorized(BuildContext context, UserEntity? user, String lounge) =>
    user != null &&
    user.isActive &&
    !user.isBanned &&
    user.loungeId == lounge &&
    (user.isLoungeAdmin || context.hasPermission('billing_checkout'));

class BookingRefundDialog extends StatefulWidget {
  final Booking booking;
  const BookingRefundDialog({super.key, required this.booking});
  @override
  State<BookingRefundDialog> createState() => _BookingRefundDialogState();
}

class _BookingRefundDialogState extends State<BookingRefundDialog> {
  final _amount = TextEditingController(),
      _reason = TextEditingController(),
      _evidence = TextEditingController();
  String? _collection, _request;
  bool _override = false, _attested = false;
  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    _evidence.dispose();
    super.dispose();
  }

  String _money(int minor) =>
      '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')} ${AppStrings.egp}';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<LoginCubit>().state.user;
    context.watch<PermissionsCubit?>();
    final shifts = context.watch<ShiftCubit>().state;
    final shift = shifts.activeShift;
    final ownOpenShift =
        shifts.status.isActive &&
        shift?.status == 'open' &&
        shift?.loungeId == widget.booking.loungeId &&
        shift?.cashierId == user?.id;
    final allowed = _authorized(context, user, widget.booking.loungeId);
    return BlocBuilder<BookingRefundCubit, BookingRefundState>(
      builder: (context, state) {
        final cubit = context.read<BookingRefundCubit>(),
            summary = state.summary;
        final enabled =
            allowed &&
            cubit.repository.writesEnabled &&
            state.fresh &&
            !state.busy;
        final collections =
            summary?.movements
                .where(
                  (m) => m.supportsCashReturn && summary.availableFor(m) > 0,
                )
                .toList() ??
            <RefundMovement>[];
        final requests =
            summary?.requests
                .where(
                  (r) =>
                      r.status == 'approved_pending_return' &&
                      summary.movements.any(
                        (m) => m.id == r.collectionId && m.supportsCashReturn,
                      ),
                )
                .toList() ??
            <BookingRefundRequest>[];
        final selectedCollection = collections
            .where((m) => m.id == _collection)
            .firstOrNull;
        final selectedRequest = requests
            .where((r) => r.id == _request)
            .firstOrNull;
        final amount = refundAmountMinor(_amount.text);
        return AlertDialog(
          title: Text(AppStrings.refundManage),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.refundSeparation),
                  if (state.busy) const LinearProgressIndicator(),
                  if (!allowed) Text(AppStrings.refundPermissionLost),
                  if (!cubit.repository.writesEnabled)
                    Text(AppStrings.refundRolloutBlocked),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(switch (state.error!) {
                        RefundFailureKind.uncertain ||
                        RefundFailureKind.pending => AppStrings.refundUncertain,
                        RefundFailureKind.denied =>
                          AppStrings.refundPermissionLost,
                        _ => AppStrings.refundFailed,
                      }),
                    ),
                  if (state.receipt case final receipt? when allowed)
                    SelectableText(
                      '${receipt.moneyReturned ? AppStrings.refundReturnConfirmed : AppStrings.refundRequestConfirmed}'
                      '\n${_money(receipt.amountMinor)}\n${receipt.movementId ?? receipt.requestId}',
                    ),
                  if (summary != null && allowed) ...[
                    const SizedBox(height: 12),
                    _row(AppStrings.refundGross, _money(summary.grossMinor)),
                    _row(
                      AppStrings.refundReturned,
                      _money(summary.refundedMinor),
                    ),
                    _row(AppStrings.refundNet, _money(summary.netMinor)),
                    _row(
                      AppStrings.refundPending,
                      _money(summary.pendingMinor),
                    ),
                    _row(
                      AppStrings.refundRemaining,
                      _money(summary.remainingMinor),
                    ),
                    Text(AppStrings.refundRemainingHelp),
                    for (final request in summary.requests)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(_money(request.amountMinor)),
                        subtitle: Text(switch (request.status) {
                          'completed' => AppStrings.refundReturnConfirmed,
                          'cancelled' => AppStrings.refundRequestCancelled,
                          _ => AppStrings.refundRequestConfirmed,
                        }),
                      ),
                    const Divider(),
                    Text(AppStrings.refundCashScope),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCollection?.id,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: AppStrings.refundCollection,
                      ),
                      items: collections
                          .map(
                            (m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(
                                '${_money(summary.availableFor(m))} · ${m.id.substring(0, 8)}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: enabled
                          ? (v) => setState(() => _collection = v)
                          : null,
                    ),
                    TextField(
                      controller: _amount,
                      enabled: enabled,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: AppStrings.amountEgp,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    TextField(
                      controller: _reason,
                      enabled: enabled,
                      maxLength: 500,
                      decoration: InputDecoration(
                        labelText: AppStrings.reasonDetails,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (user?.isLoungeAdmin == true)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _override,
                        title: Text(AppStrings.refundPolicyOverride),
                        onChanged: enabled
                            ? (v) => setState(() => _override = v ?? false)
                            : null,
                      ),
                    FilledButton(
                      onPressed:
                          enabled &&
                              selectedCollection != null &&
                              amount != null &&
                              amount <=
                                  summary.availableFor(selectedCollection) &&
                              _reason.text.trim().isNotEmpty
                          ? () => cubit.initiate(
                              selectedCollection.id,
                              amount,
                              _reason.text,
                              _override,
                            )
                          : null,
                      child: Text(AppStrings.refundCreateRequest),
                    ),
                    const Divider(),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRequest?.id,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: AppStrings.refundPending,
                      ),
                      items: requests
                          .map(
                            (r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(
                                '${_money(r.amountMinor)} · ${r.id.substring(0, 8)}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: enabled
                          ? (v) => setState(() {
                              _request = v;
                              _attested = false;
                            })
                          : null,
                    ),
                    TextField(
                      controller: _evidence,
                      enabled: enabled,
                      maxLength: 500,
                      decoration: InputDecoration(
                        labelText: AppStrings.fundsEvidenceReference,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _attested,
                      title: Text(AppStrings.refundAttestation),
                      onChanged: enabled
                          ? (v) => setState(() => _attested = v ?? false)
                          : null,
                    ),
                    if (!ownOpenShift) Text(AppStrings.refundOwnShift),
                    FilledButton(
                      onPressed:
                          enabled &&
                              ownOpenShift &&
                              selectedRequest != null &&
                              _attested &&
                              _evidence.text.trim().isNotEmpty
                          ? () => cubit.execute(
                              selectedRequest,
                              shift!.id,
                              _evidence.text,
                            )
                          : null,
                      child: Text(AppStrings.refundRecordReturn),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: state.busy ? null : () => cubit.load(),
              child: Text(AppStrings.retry),
            ),
            TextButton(
              onPressed: state.busy ? null : () => Navigator.of(context).pop(),
              child: Text(AppStrings.close),
            ),
          ],
        );
      },
    );
  }

  Widget _row(String title, String amount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Wrap(spacing: 12, children: [Text(title), Text(amount)]),
  );
}
