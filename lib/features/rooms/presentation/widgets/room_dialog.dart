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
import '../../../categories/presentation/cubit/category_cubit.dart';
import '../../../categories/presentation/cubit/category_state.dart';
import '../../domain/entities/room_entity.dart';
import 'room_basic_info_form.dart';
import 'room_specs_form.dart';

class RoomDialog extends StatefulWidget {
  final String loungeId;
  final RoomEntity? room;
  final CategoryCubit categoryCubit;
  final Future<void> Function(RoomEntity)? onSave;

  const RoomDialog({
    super.key, 
    required this.loungeId, 
    required this.categoryCubit,
    this.room,
    this.onSave,
  });

  @override
  State<RoomDialog> createState() => _RoomDialogState();
}

class _RoomDialogState extends State<RoomDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _priceController;
  late TextEditingController _capacityController;
  late TextEditingController _controllersController;
  late TextEditingController _screenSizeController;
  
  final List<String> _selectedActivityIds = [];
  final List<String> _featuresAr = [];
  final List<String> _featuresEn = [];
  
  RoomStatusEnum _selectedStatus = RoomStatusEnum.available;
  String? _selectedSpaceType;
  List<SelectedImage> _roomImages = [];
  bool _isUploading = false;

  final TextEditingController _featureArController = TextEditingController();
  final TextEditingController _featureEnController = TextEditingController();

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
    _selectedStatus = r?.status ?? RoomStatusEnum.available;
    if (r != null) {
      _selectedActivityIds.addAll(r.activityIds);
      _featuresAr.addAll(r.featuresAr);
      _featuresEn.addAll(r.featuresEn);
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
    _featureArController.dispose();
    _featureEnController.dispose();
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
            activityIds: _selectedActivityIds,
            featuresAr: _featuresAr,
            featuresEn: _featuresEn,
            images: images,
            isAvailable: _selectedStatus == RoomStatusEnum.available,
            status: _selectedStatus,
          );

          if (widget.onSave != null) {
            await widget.onSave!(room);
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
        width: 800.w,
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
                  status: _selectedStatus,
                  onStatusChanged: (v) => setState(() => _selectedStatus = v!),
                ),
                SizedBox(height: 24.h),
                _buildFeaturesSection(),
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

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.specs, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w500)),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _featureArController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'المميزات (عربي)',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.mutedBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TextFormField(
                controller: _featureEnController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Features (English)',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.mutedBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            IconButton(
              onPressed: () {
                if (_featureArController.text.isNotEmpty && _featureEnController.text.isNotEmpty) {
                  setState(() {
                    _featuresAr.add(_featureArController.text);
                    _featuresEn.add(_featureEnController.text);
                    _featureArController.clear();
                    _featureEnController.clear();
                  });
                }
              },
              icon: const Icon(Icons.add_circle, color: AppColors.neonBlue),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: List.generate(_featuresEn.length, (index) {
            return Chip(
              label: Text('${_featuresEn[index]} | ${_featuresAr[index]}', style: TextStyle(fontSize: 11.sp)),
              backgroundColor: AppColors.mutedBackground,
              deleteIcon: Icon(Icons.close, size: 14.r, color: AppColors.danger),
              onDeleted: () => setState(() {
                _featuresAr.removeAt(index);
                _featuresEn.removeAt(index);
              }),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r), side: BorderSide(color: AppColors.borderDefault)),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildActivitySelection() {
    return BlocBuilder<CategoryCubit, CategoryState>(
      bloc: widget.categoryCubit,
      builder: (context, state) {
        final categories = state.categories;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.categories,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: categories.map((cat) {
                final isSelected = _selectedActivityIds.contains(cat.id);
                return FilterChip(
                  label: Text(cat.nameEn),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedActivityIds.add(cat.id);
                      } else {
                        _selectedActivityIds.remove(cat.id);
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
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.room == null ? AppStrings.addNewRoom : AppStrings.editRoom,
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
          text: widget.room == null ? AppStrings.createStation : AppStrings.updateStation,
          isLoading: _isUploading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
