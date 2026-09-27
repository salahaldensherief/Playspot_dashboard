import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

class AddBookingPlayModeSelector extends StatelessWidget {
  final RoomEntity? room;
  final String selectedMode;
  final ValueChanged<String> onModeChanged;

  const AddBookingPlayModeSelector({
    super.key,
    required this.room,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final singleRate = room?.hourlyRateSingle ?? room?.pricePerHour ?? 0;
    final multiRate = (room?.hourlyRateMulti ?? 0) > 0
        ? room!.hourlyRateMulti
        : singleRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body("طريقة اللعب (Play Mode)", fontWeight: FontWeight.bold),
        SizedBox(height: 8.h),
        SegmentedButton<String>(
          segments: [
            ButtonSegment<String>(
              value: 'single',
              label: Text('${AppStrings.single} (${singleRate.toStringAsFixed(0)} ${AppStrings.egp}/hr)'),
              icon: const Icon(Icons.person_outline_rounded),
            ),
            ButtonSegment<String>(
              value: 'multi',
              label: Text('${AppStrings.multi} (${multiRate.toStringAsFixed(0)} ${AppStrings.egp}/hr)'),
              icon: const Icon(Icons.people_outline_rounded),
            ),
          ],
          selected: {selectedMode},
          onSelectionChanged: (Set<String> newSelection) {
            if (newSelection.isNotEmpty) {
              onModeChanged(newSelection.first);
            }
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.neonBlue.withValues(alpha: 0.2);
              }
              return AppColors.cardBackground;
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.neonBlue;
              }
              return AppColors.textPrimary;
            }),
            side: WidgetStateProperty.all(
              const BorderSide(color: AppColors.borderDefault),
            ),
          ),
        ),
      ],
    );
  }
}
