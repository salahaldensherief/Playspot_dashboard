import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import '../theme/app_colors.dart';

class SelectedImage {
  final Uint8List bytes;
  final String name;

  SelectedImage({required this.bytes, required this.name});
}

class AppMultiImagePicker extends StatefulWidget {
  final String label;
  final Function(List<SelectedImage> images) onImagesSelected;
  final int maxImages;
  final List<String>? initialUrls;

  const AppMultiImagePicker({
    super.key,
    required this.label,
    required this.onImagesSelected,
    this.maxImages = 8,
    this.initialUrls,
  });

  @override
  State<AppMultiImagePicker> createState() => _AppMultiImagePickerState();
}

class _AppMultiImagePickerState extends State<AppMultiImagePicker> {
  final List<SelectedImage> _selectedImages = [];

  Future<void> _pickImages() async {
    if (_selectedImages.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.maxImagesError), backgroundColor: AppColors.danger),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        final newImages = result.files
            .where((f) => f.bytes != null)
            .map((f) => SelectedImage(bytes: f.bytes!, name: f.name))
            .toList();

        setState(() {
          for (var img in newImages) {
            if (_selectedImages.length < widget.maxImages) {
              _selectedImages.add(img);
            }
          }
        });
        widget.onImagesSelected(_selectedImages);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    widget.onImagesSelected(_selectedImages);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              AppStrings.imagesCount.replaceFirst('{}', _selectedImages.length.toString()),
              style: TextStyle(
                color: _selectedImages.isEmpty ? AppColors.textSecondary : AppColors.neonBlue,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: AppColors.mutedBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              ...List.generate(_selectedImages.length, (index) {
                return Stack(
                  children: [
                    Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.neonBlue, width: 1.5),
                        image: DecorationImage(
                          image: MemoryImage(_selectedImages[index].bytes),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              if (_selectedImages.length < widget.maxImages)
                InkWell(
                  onTap: _pickImages,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    width: 100.w,
                    height: 100.h,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary, size: 24.r),
                        SizedBox(height: 4.h),
                        Text(
                          'Add',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
