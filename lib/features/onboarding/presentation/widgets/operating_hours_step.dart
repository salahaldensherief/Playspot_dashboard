import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/widgets/app_text_field.dart';

class OperatingHoursStep extends StatelessWidget {
  final TextEditingController opensAtController;
  final TextEditingController closesAtController;

  const OperatingHoursStep({
    super.key,
    required this.opensAtController,
    required this.closesAtController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.opensAt,
                hintText: AppStrings.timeHint,
                controller: opensAtController,
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.closesAt,
                hintText: AppStrings.timeHint,
                controller: closesAtController,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
