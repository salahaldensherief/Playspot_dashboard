import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_multi_image_picker.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../cubit/room_cubit.dart';
import '../../domain/entities/room_entity.dart';
import 'room_basic_info_form.dart';
import 'room_specs_form.dart';

class RoomDialog extends StatefulWidget {
  final String loungeId;
  final RoomEntity? room;
  const RoomDialog({super.key, required this.loungeId, this.room});

  @override
  State<RoomDialog> createState() => _RoomDialogState();
}

class _RoomDialogState extends State<RoomDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _priceController;
  late TextEditingController _capacityController;
  late TextEditingController _controllersController;
  late TextEditingController _screenSizeController;
  
  final List<String> _selectedActivities = [];
  final List<String> _predefinedActivities = ['PS5', 'PC', 'VR', 'Billiards'];
  
  String? _selectedSpaceType;
  List<SelectedImage> _roomImages = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _nameArController = TextEditingController(text: r?.nameAr);
    _nameEnController = TextEditingController(text: r?.nameEn);
    _priceController = TextEditingController(text: r?.pricePerHour.toString());
    _capacityController = TextEditingController(text: r?.capacity.toString());
    _controllersController = TextEditingController(text: r?.controllersCount.toString() ?? '2');
    _screenSizeController = TextEditingController(text: r?.screenSize ?? '43"');
    _selectedSpaceType = r?.spaceType ?? 'Private';
    if (r != null) {
      _selectedActivities.addAll(r.activityNames);
    }
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _controllersController.dispose();
    _screenSizeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_roomImages.isEmpty && (widget.room?.images == null || widget.room!.images.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.minImagesError), backgroundColor: AppColors.danger),
        );
        return;
      }

      setState(() => _isUploading = true);
      
      try {
        List<String> images = widget.room?.images ?? [];
        if (_roomImages.isNotEmpty) {
          final newUrls = await sl<StorageService>().uploadRoomImages(
            _roomImages.map((e) => e.bytes).toList(), 
            _roomImages.map((e) => e.name).toList(),
            widget.loungeId,
          );
          images = [...images, ...newUrls];
        }

        if (mounted) {
          final room = RoomEntity(
            id: widget.room?.id ?? const Uuid().v4(),
            loungeId: widget.loungeId,
            nameAr: _nameArController.text,
            nameEn: _nameEnController.text,
            spaceType: _selectedSpaceType,
            pricePerHour: double.tryParse(_priceController.text) ?? 0,
            capacity: int.tryParse(_capacityController.text) ?? 1,
            controllersCount: int.tryParse(_controllersController.text) ?? 2,
            screenSize: _screenSizeController.text,
            activityNames: _selectedActivities.isEmpty ? const ['PS5'] : _selectedActivities,
            featuresAr: widget.room?.featuresAr ?? const [],
            featuresEn: widget.room?.featuresEn ?? const [],
            images: images,
            isAvailable: widget.room?.isAvailable ?? true,
            status: widget.room?.status ?? RoomStatus.available,
          );

          if (widget.room == null) {
            try {
              await context.read<RoomCubit>().addNewRoom(room);
            } catch (e) {
              await context.read<OnboardingCubit>().addNewRoom(room);
            }
          } else {
             // TODO: Implement updateRoom in Cubit
             // await context.read<RoomCubit>().updateRoom(room);
          }

          if (mounted) Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 700.w,
        padding: EdgeInsets.all(32.r),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 32.h),
                AppMultiImagePicker(
                  label: AppStrings.roomStationImage,
                  initialUrls: widget.room?.images,
                  onImagesSelected: (images) {
                    _roomImages = images;
                  },
                ),
                SizedBox(height: 24.h),
                RoomBasicInfoForm(
                  nameArController: _nameArController,
                  nameEnController: _nameEnController,
                  priceController: _priceController,
                ),
                SizedBox(height: 20.h),
                RoomSpecsForm(
                  capacityController: _capacityController,
                  controllersController: _controllersController,
                  screenSizeController: _screenSizeController,
                  selectedSpaceType: _selectedSpaceType,
                  onSpaceTypeChanged: (v) => setState(() => _selectedSpaceType = v),
                ),
                SizedBox(height: 24.h),
                _buildActivitySelection(),
                SizedBox(height: 32.h),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activities',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: _predefinedActivities.map((activity) {
            final isSelected = _selectedActivities.contains(activity);
            return FilterChip(
              label: Text(activity),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedActivities.add(activity);
                  } else {
                    _selectedActivities.remove(activity);
                  }
                });
              },
              backgroundColor: AppColors.mutedBackground,
              selectedColor: AppColors.neonBlue.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
                fontSize: 12.sp,
              ),
              checkmarkColor: AppColors.neonBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
                side: BorderSide(
                  color: isSelected ? AppColors.neonBlue : AppColors.borderDefault,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.room == null ? AppStrings.addNewRoom : 'Edit Room / Station',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 16.w),
        AppButton(
          text: widget.room == null ? AppStrings.createStation : 'Update Station',
          isLoading: _isUploading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
