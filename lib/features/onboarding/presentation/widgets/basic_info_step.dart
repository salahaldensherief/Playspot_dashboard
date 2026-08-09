import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../art_core/widgets/app_text_field.dart';

class BasicInfoStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  const BasicInfoStep({
    super.key,
    required this.nameController,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: 'Lounge Name',
          hintText: 'Enter your lounge name',
          controller: nameController,
        ),
        SizedBox(height: 20.h),
        AppTextField(
          label: 'Description',
          hintText: 'Tell players about your lounge',
          controller: descriptionController,
        ),
      ],
    );
  }
}
