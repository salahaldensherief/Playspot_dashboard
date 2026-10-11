import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../art_core/layouts/dashboard_layout.dart';
import '../../../art_core/theme/app_colors.dart';
import '../../../art_core/widgets/app_button.dart';
import '../../auth/presentation/login/login_cubit.dart';
import '../../auth/presentation/login/login_state.dart';
import 'offline_workspace_cubit.dart';
import 'offline_workspace_state.dart';
import '../domain/entities/local_cashier_command.dart';
import 'widgets/offline_reservation_dialog.dart';
import 'widgets/offline_sale_dialog.dart';
import 'widgets/cashier_conflict_review.dart';

class OfflineWorkspacePage extends StatefulWidget {
  const OfflineWorkspacePage({super.key});
  @override
  State<OfflineWorkspacePage> createState() => _OfflineWorkspacePageState();
}

class _OfflineWorkspacePageState extends State<OfflineWorkspacePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  void _load() {
    final user = context.read<LoginCubit>().state.user;
    context.read<OfflineWorkspaceCubit>().load(
      user?.id ?? '',
      user?.loungeId ?? '',
    );
  }

  Future<void> _confirm(String key, Future<void> Function() action) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(key.tr()),
        content: Text('${key}_help'.tr()),
        actions: [
          AppButton(
            text: 'offline_workspace.cancel'.tr(),
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            text: 'offline_workspace.confirm'.tr(),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (yes == true && mounted) await action();
  }

  @override
  Widget build(BuildContext context) => BlocListener<LoginCubit, LoginState>(
    listenWhen: (a, b) =>
        a.user?.id != b.user?.id || a.user?.loungeId != b.user?.loungeId,
    listener: (_, s) => _load(),
    child: Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: DashboardLayout(
        child: BlocBuilder<OfflineWorkspaceCubit, OfflineWorkspaceState>(
          buildWhen: (a, b) => a != b,
          builder: (context, state) {
            final cubit = context.read<OfflineWorkspaceCubit>();
            final bookings = state.visibleBookings;
            final conflicts = state.snapshot['sync_conflicts'] as Map? ?? {};
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'offline_workspace.title'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text('offline_workspace.explanation'.tr()),
                if (state.prepared)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      (state.canOperate
                              ? 'offline_workspace.local_mode'
                              : 'offline_workspace.paused_mode')
                          .tr(),
                    ),
                  ),
                const SizedBox(height: 12),
                if (state.status == OfflineWorkspaceStatus.loading)
                  const LinearProgressIndicator(),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      state.error?.tr() ?? '',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
                    ),
                  ),
                Text(
                  'offline_workspace.pending'.tr(
                    args: [state.pending.toString()],
                  ),
                ),
                if (conflicts.isNotEmpty)
                  Text(
                    'offline_workspace.conflicts'.tr(
                      args: [conflicts.length.toString()],
                    ),
                  ),
                if (state.snapshot['writer_release'] != null)
                  Text('offline_cashier.release_pending'.tr()),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      text: 'offline_workspace.prepare'.tr(),
                      onPressed: state.busy
                          ? null
                          : () => _confirm(
                              'offline_workspace.prepare',
                              cubit.prepare,
                            ),
                    ),
                    AppButton(
                      text: 'offline_workspace.sync'.tr(),
                      onPressed: state.busy || !state.prepared
                          ? null
                          : cubit.synchronize,
                      variant: AppButtonVariant.outlined,
                    ),
                    AppButton(
                      text: 'offline_workspace.resume'.tr(),
                      onPressed:
                          state.busy ||
                              state.status != OfflineWorkspaceStatus.ready
                          ? null
                          : () => _confirm(
                              'offline_workspace.resume',
                              cubit.resumeOnline,
                            ),
                      variant: AppButtonVariant.outlined,
                    ),
                    AppButton(
                      text: 'offline_workspace.release'.tr(),
                      onPressed: state.busy || !state.prepared
                          ? null
                          : () => _confirm(
                              'offline_workspace.release',
                              cubit.release,
                            ),
                      variant: AppButtonVariant.outlined,
                    ),
                    AppButton(
                      text: 'offline_workspace.new_booking'.tr(),
                      onPressed: state.busy || !state.canOperate
                          ? null
                          : () => showDialog(
                              context: context,
                              builder: (_) =>
                                  OfflineReservationDialog(cubit: cubit),
                            ),
                    ),
                  ],
                ),
                if (state.busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  ),
                const SizedBox(height: 16),
                if (bookings.isEmpty) Text('offline_workspace.empty'.tr()),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1100
                        ? 3
                        : constraints.maxWidth >= 650
                        ? 2
                        : 1;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final value in bookings.values)
                          if (value is Map)
                            SizedBox(
                              width: width,
                              child: _booking(context, cubit, state, value),
                            ),
                      ],
                    );
                  },
                ),
                if (context.read<LoginCubit>().state.user case final user?)
                  if (user.isManager || user.isOwner || user.isSuperAdmin)
                    CashierConflictReview(
                      actorId: user.id,
                      loungeId: user.loungeId ?? '',
                    ),
                for (final value in conflicts.values)
                  if (value is Map)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'offline_workspace.conflict_saved'.tr(
                            args: [_conflictReason(value['code']).tr()],
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    ),
  );
  String _conflictReason(Object? code) => switch (code) {
    'OFFLINE_ROOM_CONFLICT' => 'offline_cashier.room_conflict',
    'OFFLINE_INSUFFICIENT_STOCK' => 'offline_cashier.insufficient_stock',
    'OFFLINE_PRODUCT_UNAVAILABLE' => 'offline_workspace.product_unavailable',
    'OFFLINE_PRODUCT_PRICE_CHANGED' ||
    'OFFLINE_BOOKING_PRICE_CHANGED' => 'offline_workspace.price_conflict',
    'OFFLINE_SEQUENCE_GAP' ||
    'OFFLINE_SEQUENCE_BLOCKED' => 'offline_cashier.sequence_mismatch',
    _ => 'offline_workspace.review_conflict',
  };
  Widget _booking(
    BuildContext context,
    OfflineWorkspaceCubit cubit,
    OfflineWorkspaceState state,
    Map booking,
  ) {
    final room = (state.snapshot['rooms'] as Map?)?[booking['room_id']] as Map?;
    final start = DateTime.fromMillisecondsSinceEpoch(
      booking['start_ms'] as int? ?? 0,
    ).toLocal();
    final end = DateTime.fromMillisecondsSinceEpoch(
      booking['end_ms'] as int? ?? 0,
    ).toLocal();
    final total = (booking['total_minor'] as int? ?? 0);
    final paid = (booking['paid_minor'] as int? ?? 0);
    final enabled =
        !state.busy && state.canOperate && booking['offline_supported'] == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${room?['name'] ?? ''} · ${booking['customer_name'] ?? ''}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('offline_workspace.${booking['status']}'.tr()),
            Text(
              '${DateFormat.yMd(context.locale.toString()).add_Hm().format(start)} — ${DateFormat.Hm(context.locale.toString()).format(end)}',
            ),
            Text(
              'offline_workspace.balance'.tr(
                args: [
                  (total / 100).toStringAsFixed(2),
                  (paid / 100).toStringAsFixed(2),
                  ((total - paid) / 100).toStringAsFixed(2),
                ],
              ),
            ),
            Text(
              (booking['sync_status'] == 'pending'
                      ? 'offline_workspace.saved'
                      : 'offline_workspace.synced')
                  .tr(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (booking['status'] == 'upcoming')
                  AppButton(
                    text: 'offline_workspace.start'.tr(),
                    onPressed: enabled
                        ? () => cubit.execute(
                            LocalCashierCommandKind.start,
                            booking['id'] as String,
                            {},
                          )
                        : null,
                  ),
                if (booking['status'] == 'in_progress') ...[
                  AppButton(
                    text: 'offline_workspace.order'.tr(),
                    onPressed: enabled
                        ? () => showDialog(
                            context: context,
                            builder: (_) => OfflineSaleDialog(
                              cubit: cubit,
                              bookingId: booking['id'] as String,
                              cash: false,
                            ),
                          )
                        : null,
                    variant: AppButtonVariant.outlined,
                  ),
                  AppButton(
                    text: 'offline_workspace.close'.tr(),
                    onPressed: enabled
                        ? () => _confirm(
                            'offline_workspace.close',
                            () => cubit.execute(
                              LocalCashierCommandKind.close,
                              booking['id'] as String,
                              {},
                            ),
                          )
                        : null,
                    variant: AppButtonVariant.outlined,
                  ),
                ],
                if (total > paid &&
                    !['cancelled', 'rejected'].contains(booking['status']))
                  AppButton(
                    text: 'offline_workspace.cash'.tr(),
                    onPressed: enabled
                        ? () => showDialog(
                            context: context,
                            builder: (_) => OfflineSaleDialog(
                              cubit: cubit,
                              bookingId: booking['id'] as String,
                              cash: true,
                            ),
                          )
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
