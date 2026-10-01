import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/theme/operations_tokens.dart';
import '../../../../art_core/widgets/app_button.dart';

class CashierSessionSheet extends StatelessWidget {
  final ValueNotifier<int> revision;
  final Widget Function() details;
  const CashierSessionSheet({
    super.key,
    required this.revision,
    required this.details,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height,
    child: Column(
      children: [
        AppButton(
          text: 'cashier.back'.tr(),
          fontSize: OperationsTokens.valueFontSize,
          height: OperationsTokens.actionHeight,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: revision,
            builder: (_, revision, child) =>
                SingleChildScrollView(child: details()),
          ),
        ),
      ],
    ),
  );
}
