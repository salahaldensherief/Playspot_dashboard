import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';

void main() {
  test('muted dashboard text remains readable on dark surfaces', () {
    for (final surface in [
      AppColors.cardBackground,
      AppColors.mutedBackground,
      AppColors.scaffoldBackground,
    ]) {
      final light = math.max(
        AppColors.textMuted.computeLuminance(),
        surface.computeLuminance(),
      );
      final dark = math.min(
        AppColors.textMuted.computeLuminance(),
        surface.computeLuminance(),
      );
      expect((light + 0.05) / (dark + 0.05), greaterThanOrEqualTo(4.5));
    }
  });
}
