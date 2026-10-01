import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../app_strings.dart';
import '../theme/app_colors.dart';
import 'app_cached_image.dart';

class AppImagePicker extends StatefulWidget {
  final String label;
  final Function(Uint8List? bytes, String? name) onImageSelected;
  final double? height;
  final double? fontSize;
  final bool allowPdf;
  final String? initialImageUrl;

  const AppImagePicker({
    super.key,
    required this.label,
    required this.onImageSelected,
    this.height,
    this.fontSize,
    this.allowPdf = false,
    this.initialImageUrl,
  });

  @override
  State<AppImagePicker> createState() => _AppImagePickerState();
}

class _AppImagePickerState extends State<AppImagePicker> {
  Uint8List? _selectedBytes;
  String? _selectedPdfName;

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: widget.allowPdf ? FileType.custom : FileType.image,
        allowedExtensions: widget.allowPdf
            ? const ['jpg', 'jpeg', 'png', 'webp', 'pdf']
            : null,
        allowMultiple: false,
        withData: true, // Critical for Web to get bytes
      );

      if (mounted && result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedBytes = file.bytes;
          _selectedPdfName = file.name.toLowerCase().endsWith('.pdf')
              ? file.name
              : null;
        });
        widget.onImageSelected(file.bytes, file.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorPickingImage(e.toString())),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasInitialImage =
        widget.initialImageUrl != null &&
        widget.initialImageUrl!.trim().isNotEmpty;
    final hasImage = _selectedBytes != null || hasInitialImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: widget.fontSize ?? 14.sp,
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
                color: hasImage ? AppColors.neonBlue : AppColors.borderDefault,
                style: BorderStyle.solid,
              ),
            ),
            child: _selectedPdfName != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.picture_as_pdf_outlined, size: 32),
                        Text(
                          _selectedPdfName ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: widget.fontSize ?? 14.sp),
                        ),
                      ],
                    ),
                  )
                : _selectedBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.memory(_selectedBytes!, fit: BoxFit.cover),
                  )
                : hasInitialImage
                ? AppCachedImage(
                    imageUrl: widget.initialImageUrl,
                    height: widget.height ?? 150.h,
                    borderRadius: 12.r,
                    fit: BoxFit.cover,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.textSecondary,
                        size: widget.fontSize != null ? 32 : 32.r,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        AppStrings.uploadInstruction,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: widget.fontSize ?? 12.sp,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
