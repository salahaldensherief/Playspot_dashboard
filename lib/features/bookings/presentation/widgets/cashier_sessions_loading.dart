import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/theme/operations_tokens.dart';

class CashierSessionsLoading extends StatelessWidget {
  const CashierSessionsLoading({super.key});
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: AppColors.cardBackground,
    highlightColor: AppColors.mutedBackground,
    child: Column(
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: OperationsTokens.gap),
            decoration: OperationsTokens.panel,
          ),
      ],
    ),
  );
}
