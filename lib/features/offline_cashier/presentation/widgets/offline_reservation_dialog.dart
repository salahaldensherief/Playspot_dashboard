import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../offline_workspace_cubit.dart';
import '../../domain/entities/local_cashier_command.dart';

class OfflineReservationDialog extends StatefulWidget {
  final OfflineWorkspaceCubit cubit;
  const OfflineReservationDialog({super.key, required this.cubit});
  @override
  State<OfflineReservationDialog> createState() =>
      _OfflineReservationDialogState();
}

class _OfflineReservationDialogState extends State<OfflineReservationDialog> {
  final name = TextEditingController();
  final phone = TextEditingController();
  String? room;
  String mode = 'single';
  int minutes = 60;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty || room == null) return;
    setState(() => busy = true);
    final start =
        (widget.cubit.clock().millisecondsSinceEpoch ~/ 60000) * 60000;
    await widget.cubit
        .execute(LocalCashierCommandKind.reserve, const Uuid().v4(), {
          'room_id': room,
          'customer_name': name.text.trim(),
          'customer_phone': phone.text.trim(),
          'play_mode': mode,
          'start_ms': start,
          'end_ms': start + minutes * 60000,
          'timezone':
              (widget.cubit.state.snapshot['authority'] as Map?)?['timezone'],
        });
    if (!mounted) return;
    if (widget.cubit.state.error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      busy = false;
      error = widget.cubit.state.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rooms = widget.cubit.state.snapshot['rooms'] as Map? ?? {};
    return AlertDialog(
      title: Text('offline_workspace.new_booking'.tr()),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('offline_workspace.fixed_only'.tr()),
              TextField(
                controller: name,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: 'offline_workspace.customer'.tr(),
                ),
              ),
              TextField(
                controller: phone,
                maxLength: 32,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'offline_workspace.phone'.tr(),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: room,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'offline_workspace.room'.tr(),
                ),
                items: rooms.entries
                    .where(
                      (e) =>
                          e.value['offline_supported'] == true &&
                          e.value['is_active'] == true,
                    )
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key.toString(),
                        child: Text(
                          e.value['name']?.toString() ?? e.key.toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) => setState(() => room = value),
              ),
              DropdownButtonFormField<String>(
                initialValue: mode,
                isExpanded: true,
                items: ['single', 'multi']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('offline_workspace.$value'.tr()),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) => setState(() => mode = value ?? 'single'),
              ),
              DropdownButtonFormField<int>(
                initialValue: minutes,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'offline_workspace.duration'.tr(),
                ),
                items: [30, 60, 90, 120, 180, 240]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          'offline_workspace.minutes'.tr(
                            args: [value.toString()],
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) => setState(() => minutes = value ?? 60),
              ),
              if (error != null) Text(error?.tr() ?? ''),
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          text: 'offline_workspace.cancel'.tr(),
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          variant: AppButtonVariant.text,
        ),
        AppButton(
          text: 'offline_workspace.save_local'.tr(),
          isLoading: busy,
          onPressed: busy ? null : save,
        ),
      ],
    );
  }
}
