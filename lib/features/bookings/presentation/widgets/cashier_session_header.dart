import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/theme/operations_tokens.dart';
import '../../../../art_core/widgets/app_button.dart';

class CashierSessionHeader extends StatelessWidget {
  final String roomName;
  final VoidCallback? onManage;
  const CashierSessionHeader({
    super.key,
    required this.roomName,
    this.onManage,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale =
          (MediaQuery.textScalerOf(
                    context,
                  ).scale(OperationsTokens.valueFontSize) /
                  OperationsTokens.valueFontSize)
              .clamp(1.0, 3.0);
      final compact =
          constraints.maxWidth < OperationsTokens.headerMinimumWidth * scale;
      final title = Text(roomName, style: OperationsTokens.title);
      if (onManage == null) return title;
      return Flex(
        direction: compact ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: compact
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        children: [
          if (compact) title else Expanded(child: title),
          const SizedBox(
            width: OperationsTokens.gap,
            height: OperationsTokens.gap,
          ),
          AppButton(
            text: 'cashier.manage'.tr(),
            onPressed: onManage,
            variant: AppButtonVariant.outlined,
            foregroundColor: AppColors.neonCyan,
            fontSize: OperationsTokens.value.fontSize,
            height: OperationsTokens.actionHeight,
            width: compact
                ? constraints.maxWidth
                : OperationsTokens.actionWidth,
          ),
        ],
      );
    },
  );
}
