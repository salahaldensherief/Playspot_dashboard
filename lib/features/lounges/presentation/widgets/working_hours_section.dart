import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';

class WorkingHoursSection extends StatelessWidget {
  final TextEditingController opensAtController;
  final TextEditingController closesAtController;
  final VoidCallback onOpensAtTap;
  final VoidCallback onClosesAtTap;

  const WorkingHoursSection({
    super.key,
    required this.opensAtController,
    required this.closesAtController,
    required this.onOpensAtTap,
    required this.onClosesAtTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    final opensAtField = AppTextField(
      label: AppStrings.opensAt,
      controller: opensAtController,
      hintText: AppStrings.timeHint,
      prefixIcon: Icons.access_time,
      readOnly: true,
      onTap: onOpensAtTap,
    );

    final closesAtField = AppTextField(
      label: AppStrings.closesAt,
      controller: closesAtController,
      hintText: AppStrings.timeHint,
      prefixIcon: Icons.access_time,
      readOnly: true,
      onTap: onClosesAtTap,
    );

    return SectionContainer(
      title: AppStrings.schedule,
      children: [
        if (isCompact) ...[
          opensAtField,
          const SizedBox(height: 16),
          closesAtField,
        ] else ...[
          Row(
            children: [
              Expanded(child: opensAtField),
              const SizedBox(width: 16),
              Expanded(child: closesAtField),
            ],
          ),
        ],
      ],
    );
  }
}
