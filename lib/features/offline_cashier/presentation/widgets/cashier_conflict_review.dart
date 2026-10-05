import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../cashier_conflict_cubit.dart';
import '../cashier_conflict_state.dart';

class CashierConflictReview extends StatefulWidget {
  final String actorId;
  final String loungeId;

  const CashierConflictReview({
    super.key,
    required this.actorId,
    required this.loungeId,
  });

  @override
  State<CashierConflictReview> createState() => _CashierConflictReviewState();
}

class _CashierConflictReviewState extends State<CashierConflictReview> {
  @override
  void initState() {
    super.initState();
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(CashierConflictReview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actorId != widget.actorId ||
        oldWidget.loungeId != widget.loungeId) {
      _scheduleLoad();
    }
  }

  void _scheduleLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CashierConflictCubit>().load(
          widget.actorId,
          widget.loungeId,
        );
      }
    });
  }

  Future<void> _review(String operationId) async {
    final actor = widget.actorId;
    final lounge = widget.loungeId;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReasonDialog(),
    );
    if (mounted &&
        actor == widget.actorId &&
        lounge == widget.loungeId &&
        reason != null) {
      await context.read<CashierConflictCubit>().approve(operationId, reason);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CashierConflictCubit, CashierConflictState>(
    buildWhen: (a, b) => a != b,
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          'offline_conflicts.title'.tr(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text('offline_conflicts.explanation'.tr()),
        if (state.status == CashierConflictStatus.loading || state.busy)
          const LinearProgressIndicator(),
        if (state.error != null) Text(state.error?.tr() ?? ''),
        AppButton(
          text: 'offline_conflicts.refresh'.tr(),
          variant: AppButtonVariant.outlined,
          onPressed: state.busy || state.status == CashierConflictStatus.loading
              ? null
              : () => context.read<CashierConflictCubit>().load(
                  widget.actorId,
                  widget.loungeId,
                ),
        ),
        if (state.status == CashierConflictStatus.ready &&
            state.conflicts.isEmpty)
          Text('offline_conflicts.empty'.tr()),
        for (final conflict in state.conflicts)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'offline_conflicts.operation'.tr(
                      args: [conflict.sequence.toString(), conflict.bookingId],
                    ),
                  ),
                  Text('offline_conflicts.kind_${conflict.kind}'.tr()),
                  Text(
                    'offline_conflicts.saved_reason'.tr(args: [conflict.code]),
                  ),
                  if (conflict.retryPending)
                    Text('offline_conflicts.waiting'.tr())
                  else
                    AppButton(
                      text: 'offline_conflicts.approve'.tr(),
                      onPressed: state.busy
                          ? null
                          : () => _review(conflict.operationId),
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog();

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('offline_conflicts.approve'.tr()),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: TextFormField(
          controller: _reasonController,
          minLines: 2,
          maxLines: 5,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: 'offline_conflicts.reason'.tr(),
          ),
          validator: (value) => (value?.trim().runes.length ?? 0) < 10
              ? 'offline_conflicts.reason_invalid'.tr()
              : null,
        ),
      ),
    ),
    actions: [
      AppButton(
        text: 'offline_workspace.cancel'.tr(),
        variant: AppButtonVariant.text,
        onPressed: () => Navigator.of(context).pop(),
      ),
      AppButton(
        text: 'offline_conflicts.approve'.tr(),
        onPressed: () {
          if (_formKey.currentState?.validate() == true) {
            Navigator.of(context).pop(_reasonController.text.trim());
          }
        },
      ),
    ],
  );
}
