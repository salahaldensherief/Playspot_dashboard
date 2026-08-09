import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_image_picker.dart';
import 'package:uuid/uuid.dart';
import '../cubit/room_cubit.dart';
import '../../domain/entities/room_entity.dart';

class AddRoomDialog extends StatefulWidget {
  final String loungeId;
  const AddRoomDialog({super.key, required this.loungeId});

  @override
  State<AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<AddRoomDialog> {
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();
  final _controllersController = TextEditingController(text: '2');
  final _screenSizeController = TextEditingController(text: '43"');
  final _formKey = GlobalKey<FormState>();
  
  Uint8List? _roomImageBytes;
  String? _roomImageName;

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
                Text(
                  AppStrings.addNewRoom,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
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
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: AppStrings.nameAr,
                        hintText: 'مثال: غرفة VIP 1',
                        controller: _nameArController,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: AppTextField(
                        label: AppStrings.nameEn,
                        hintText: 'e.g. VIP Room 01',
                        controller: _nameEnController,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: AppStrings.pricePerHour,
                        hintText: '0.00',
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: AppTextField(
                        label: AppStrings.capacity,
                        hintText: 'Persons',
                        controller: _capacityController,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: AppStrings.controllers,
                        hintText: 'e.g. 2',
                        controller: _controllersController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: AppTextField(
                        label: AppStrings.specs,
                        hintText: 'e.g. 55"',
                        controller: _screenSizeController,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),
                Row(
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
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
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
        images: const [],
        isAvailable: true,
        status: RoomStatus.available,
      );
      context.read<RoomCubit>().addNewRoom(room);
      Navigator.pop(context);
    }
  }
}
