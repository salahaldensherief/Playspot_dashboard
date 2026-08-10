import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_image_picker.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../cubit/room_cubit.dart';
import '../../domain/entities/room_entity.dart';
import 'room_basic_info_form.dart';
import 'room_specs_form.dart';

class AddRoomDialog extends StatefulWidget {
  final String loungeId;
  const AddRoomDialog({super.key, required this.loungeId});

  @override
  State<AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<AddRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();
  final _controllersController = TextEditingController(text: '2');
  final _screenSizeController = TextEditingController(text: '43"');
  
  Uint8List? _roomImageBytes;
  String? _roomImageName;
  bool _isUploading = false;

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
      setState(() => _isUploading = true);
      
      try {
        List<String> images = [];
        if (_roomImageBytes != null && _roomImageName != null) {
          final imageUrl = await sl<StorageService>().uploadRoomImage(
            _roomImageBytes!, 
            _roomImageName!,
            widget.loungeId,
          );
          images.add(imageUrl);
        }

        if (mounted) {
          final room = RoomEntity(
            id: const Uuid().v4(),
            loungeId: widget.loungeId,
            nameAr: _nameArController.text,
            nameEn: _nameEnController.text,
            pricePerHour: double.tryParse(_priceController.text) ?? 0,
            capacity: int.tryParse(_capacityController.text) ?? 1,
            controllersCount: int.tryParse(_controllersController.text) ?? 2,
            screenSize: _screenSizeController.text,
            activityNames: const ['PS5'],
            featuresAr: const [],
            featuresEn: const [],
            images: images,
            isAvailable: true,
            status: RoomStatus.available,
          );

          try {
            await context.read<RoomCubit>().addNewRoom(room);
          } catch (e) {
            // Fallback for Onboarding flow
            await context.read<OnboardingCubit>().addNewRoom(room);
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
                AppImagePicker(
                  label: AppStrings.roomStationImage,
                  height: 200.h,
                  onImageSelected: (bytes, name) {
                    _roomImageBytes = bytes;
                    _roomImageName = name;
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
                ),
                SizedBox(height: 32.h),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.addNewRoom,
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
          text: AppStrings.createStation,
          isLoading: _isUploading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
