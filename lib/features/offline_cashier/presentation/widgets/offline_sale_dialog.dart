import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../offline_workspace_cubit.dart';
import '../offline_cash_amount.dart';
import '../../domain/entities/local_cashier_command.dart';

class OfflineSaleDialog extends StatefulWidget {
  final OfflineWorkspaceCubit cubit;
  final String bookingId;
  final bool cash;
  const OfflineSaleDialog({
    super.key,
    required this.cubit,
    required this.bookingId,
    required this.cash,
  });
  @override
  State<OfflineSaleDialog> createState() => _OfflineSaleDialogState();
}

class _OfflineSaleDialogState extends State<OfflineSaleDialog> {
  final amount = TextEditingController();
  String? product;
  int quantity = 1;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final minor = widget.cash ? parseOfflineCashMinor(amount.text) : 0;
    if (widget.cash && minor == null) {
      setState(() => error = 'offline_cashier.invalid_payment');
      return;
    }
    if (!widget.cash && product == null) return;
    setState(() => busy = true);
    await widget.cubit.execute(
      widget.cash
          ? LocalCashierCommandKind.collectCash
          : LocalCashierCommandKind.addItems,
      widget.bookingId,
      widget.cash
          ? {'amount_minor': minor}
          : {
              'items': [
                {'product_id': product, 'quantity': quantity},
              ],
            },
    );
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
    final products = widget.cubit.state.snapshot['products'] as Map? ?? {};
    return AlertDialog(
      title: Text(
        (widget.cash ? 'offline_workspace.cash' : 'offline_workspace.order')
            .tr(),
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.cash)
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'offline_workspace.amount'.tr(),
                  ),
                )
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: product,
                  isExpanded: true,
                  items: products.entries
                      .where(
                        (e) =>
                            e.value['is_active'] == true &&
                            e.value['is_available'] == true,
                      )
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key.toString(),
                          child: Text(
                            '${e.value['name']} · ${(e.value['unit_price_minor'] as int? ?? 0) / 100}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: busy ? null : (v) => setState(() => product = v),
                ),
                DropdownButtonFormField<int>(
                  initialValue: quantity,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'offline_workspace.quantity'.tr(),
                  ),
                  items: List.generate(
                    10,
                    (i) =>
                        DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                  ),
                  onChanged: busy
                      ? null
                      : (v) => setState(() => quantity = v ?? 1),
                ),
              ],
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
