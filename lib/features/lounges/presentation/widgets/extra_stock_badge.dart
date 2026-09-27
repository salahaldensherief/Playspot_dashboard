import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import '../../domain/entities/extra_entity.dart';

class ExtraStockBadge extends StatelessWidget {
  final ExtraEntity extra;

  const ExtraStockBadge({super.key, required this.extra});

  @override
  Widget build(BuildContext context) {
    if (extra.isOutOfStock || (extra.trackStock && extra.stockQuantity <= 0)) {
      return StatusBadge.danger(AppStrings.outOfStock);
    } else if (extra.trackStock && extra.stockQuantity <= extra.minStockAlert) {
      return StatusBadge.warning('(${extra.stockQuantity})');
    } else if (extra.trackStock) {
      return StatusBadge.info('${extra.stockQuantity}');
    } else {
      return StatusBadge.success(AppStrings.active);
    }
  }
}
