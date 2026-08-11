import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../app_strings.dart';
import '../theme/app_colors.dart';

class AppImagePicker extends StatefulWidget {
  final String label;
  final Function(Uint8List? bytes, String? name) onImageSelected;
  final double? height;

  const AppImagePicker({
    super.key,
    required this.label,
    required this.onImageSelected,
    this.height,
  });

  @override
  State<AppImagePicker> createState() => _AppImagePickerState();
}

class _AppImagePickerState extends State<AppImagePicker> {
  Uint8List? _selectedBytes;

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Critical for Web to get bytes
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedBytes = file.bytes;
        });
        widget.onImageSelected(file.bytes, file.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            height: widget.height ?? 150.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.mutedBackground,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _selectedBytes != null ? AppColors.neonBlue : AppColors.borderDefault,
                style: BorderStyle.solid,
              ),
            ),
            child: _selectedBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.memory(_selectedBytes!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary, size: 32.r),
                      SizedBox(height: 8.h),
                      Text(
                        AppStrings.uploadInstruction,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
