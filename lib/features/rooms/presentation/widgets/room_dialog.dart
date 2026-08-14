import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_multi_image_picker.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:uuid/uuid.dart';
import '../../../categories/data/entities/category_entity.dart';
import '../../../categories/data/entities/activity_type_entity.dart';
import '../../../categories/presentation/categories/category_cubit.dart';
import '../../../categories/presentation/categories/category_state.dart';
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
  late TextEditingController _descriptionArController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _priceSingleController;
  late TextEditingController _priceMultiController;
  late TextEditingController _pricePerHourController;
  late TextEditingController _capacityController;
  late TextEditingController _controllersController;
  late TextEditingController _screenSizeController;
  late TextEditingController _extraPriceController;
  
  final List<String> _selectedActivityIds = [];
  final List<String> _featuresAr = [];
  final List<String> _featuresEn = [];
  
  RoomStatusEnum _selectedStatus = RoomStatusEnum.available;
  String? _selectedSpaceTypeId;
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
    _descriptionArController = TextEditingController(text: r?.descriptionAr);
    _descriptionEnController = TextEditingController(text: r?.descriptionEn);
    _priceSingleController = TextEditingController(text: r?.pricePerHourSingle.toString() ?? '0.0');
    _priceMultiController = TextEditingController(text: r?.pricePerHourMulti.toString() ?? '0.0');
    _pricePerHourController = TextEditingController(text: r?.pricePerHour.toString() ?? '0.0');
    _capacityController = TextEditingController(text: r?.capacity.toString() ?? (r?.isOpenArea == true ? '2' : '4'));
    _controllersController = TextEditingController(text: r?.controllersCount.toString() ?? '2');
    _screenSizeController = TextEditingController(text: r?.screenSize ?? '43"');
    _extraPriceController = TextEditingController(text: r?.extraControllerPrice.toString() ?? '0.0');
    
    // Ensure _selectedSpaceTypeId is one of the valid options
    const validSpaceTypes = ['open_area', 'standard_room', 'vip_room'];
    if (r != null && validSpaceTypes.contains(r.spaceTypeId)) {
      _selectedSpaceTypeId = r.spaceTypeId;
    } else {
      _selectedSpaceTypeId = 'open_area';
    }

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
    _descriptionArController.dispose();
    _descriptionEnController.dispose();
    _priceSingleController.dispose();
    _priceMultiController.dispose();
    _pricePerHourController.dispose();
    _capacityController.dispose();
    _controllersController.dispose();
    _screenSizeController.dispose();
    _extraPriceController.dispose();
    _featureArController.dispose();
    _featureEnController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedActivityIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least one Experience / Activity type'), backgroundColor: AppColors.danger),
        );
        return;
      }
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
          final isOpenArea = _selectedSpaceTypeId == 'open_area';
          final priceSingle = double.tryParse(_priceSingleController.text) ?? 0;
          final priceMulti = double.tryParse(_priceMultiController.text) ?? 0;
          final pricePerHour = double.tryParse(_pricePerHourController.text) ?? 0;

          final room = RoomEntity(
            id: widget.room?.id ?? const Uuid().v4(),
            loungeId: widget.loungeId,
            nameAr: _nameArController.text,
            nameEn: _nameEnController.text,
            descriptionAr: _descriptionArController.text,
            descriptionEn: _descriptionEnController.text,
            spaceType: isOpenArea ? 'Open Area' : (_selectedSpaceTypeId == 'vip_room' ? 'VIP Room' : 'Standard Room'),
            spaceTypeId: _selectedSpaceTypeId,
            pricePerHourSingle: isOpenArea ? priceSingle : pricePerHour,
            pricePerHourMulti: isOpenArea ? priceMulti : pricePerHour,
            pricePerHour: isOpenArea ? priceSingle : pricePerHour,
            extraControllerPrice: double.tryParse(_extraPriceController.text) ?? 0,
            capacity: int.tryParse(_capacityController.text) ?? (isOpenArea ? 2 : 4),
            controllersCount: isOpenArea ? (int.tryParse(_controllersController.text) ?? 2) : 2,
            screenSize: isOpenArea ? _screenSizeController.text : '',
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
                CustomDropdown<String>(
                  label: AppStrings.spaceType,
                  value: const ['open_area', 'standard_room', 'vip_room'].contains(_selectedSpaceTypeId)
                      ? _selectedSpaceTypeId!
                      : 'open_area',
                  items: const ['open_area', 'standard_room', 'vip_room'],
                  itemLabel: (id) {
                    if (id == 'open_area') return AppStrings.openArea;
                    if (id == 'standard_room') return AppStrings.standardRoom;
                    if (id == 'vip_room') return AppStrings.vipRoom;
                    return id;
                  },
                  onChanged: (v) => setState(() => _selectedSpaceTypeId = v),
                ),
                SizedBox(height: 24.h),
                _buildActivitySelection(),
                SizedBox(height: 24.h),
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
                  descriptionArController: _descriptionArController,
                  descriptionEnController: _descriptionEnController,
                  priceSingleController: _priceSingleController,
                  priceMultiController: _priceMultiController,
                  pricePerHourController: _pricePerHourController,
                  isOpenArea: _selectedSpaceTypeId == 'open_area',
                ),
                SizedBox(height: 20.h),
                RoomSpecsForm(
                  capacityController: _capacityController,
                  controllersController: _controllersController,
                  screenSizeController: _screenSizeController,
                  extraPriceController: _extraPriceController,
                  selectedSpaceTypeId: _selectedSpaceTypeId,
                  status: _selectedStatus,
                  onStatusChanged: (v) => setState(() => _selectedStatus = v!),
                  featuresEn: _featuresEn,
                  onFeatureChanged: (feature, selected) {
                    setState(() {
                      if (selected) {
                        if (!_featuresEn.contains(feature)) {
                          _featuresEn.add(feature);
                          // For simplicity, just add same to AR for now or map them
                          _featuresAr.add(feature); 
                        }
                      } else {
                        final idx = _featuresEn.indexOf(feature);
                        if (idx != -1) {
                          _featuresEn.removeAt(idx);
                          _featuresAr.removeAt(idx);
                        }
                      }
                    });
                  },
                ),
                SizedBox(height: 24.h),
                _buildFeaturesSection(),
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
    final List<String> suggestions = [];
    final List<ActivityTypeEntity> activitiesList = widget.categoryCubit.state.activityTypes;
    
    String firstActivityName = '';
    if (_selectedActivityIds.isNotEmpty && activitiesList.isNotEmpty) {
      final String targetId = _selectedActivityIds.first;
      ActivityTypeEntity? foundActivity;
      for (int i = 0; i < activitiesList.length; i++) {
        if (activitiesList[i].id == targetId) {
          foundActivity = activitiesList[i];
          break;
        }
      }
      final activity = foundActivity ?? (activitiesList.isNotEmpty ? activitiesList.first : null);
      firstActivityName = activity?.label.toLowerCase() ?? '';
    }

    if (firstActivityName.contains('simulator')) {
      suggestions.addAll(['Force Feedback', 'Direct Drive', 'Load Cell Pedals', 'Bucket Seat', 'Triple Monitor']);
    } else if (firstActivityName.contains('vr')) {
      suggestions.addAll(['Meta Quest 3', 'Valve Index', 'Wireless', 'Pro Controllers', 'Pico 4']);
    } else if (firstActivityName.contains('pc')) {
      suggestions.addAll(['RTX 4080', 'RTX 4090', 'Mechanical Keyboard', 'Gaming Mouse', '240Hz Monitor']);
    } else {
      suggestions.addAll(['PS5', 'PS4 Pro', 'DualSense Edge', '4K TV', 'Home Theater']);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.specs, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w500)),
        SizedBox(height: 12.h),
        if (suggestions.isNotEmpty) ...[
          Text('Suggested Tags:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: suggestions.map((s) {
              final isAdded = _featuresEn.contains(s);
              return ActionChip(
                label: Text(s, style: TextStyle(fontSize: 10.sp, color: isAdded ? Colors.white : AppColors.textSecondary)),
                backgroundColor: isAdded ? AppColors.neonBlue.withOpacity(0.5) : AppColors.mutedBackground,
                onPressed: () {
                  setState(() {
                    if (isAdded) {
                      final idx = _featuresEn.indexOf(s);
                      _featuresEn.removeAt(idx);
                      _featuresAr.removeAt(idx);
                    } else {
                      _featuresEn.add(s);
                      _featuresAr.add(s); // Simplification
                    }
                  });
                },
              );
            }).toList(),
          ),
          SizedBox(height: 16.h),
        ],
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
        final activities = state.activityTypes;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppStrings.experienceType} (Activity)',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [
                ...activities.map<Widget>((ActivityTypeEntity cat) {
                  final isSelected = _selectedActivityIds.contains(cat.id);
                  return FilterChip(
                    label: Text(cat.label),
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
                ActionChip(
                  label: Text(AppStrings.addNew, style: TextStyle(fontSize: 12.sp, color: AppColors.neonBlue)),
                  backgroundColor: AppColors.mutedBackground,
                  onPressed: _showAddActivityDialog,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    side: const BorderSide(color: AppColors.neonBlue),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showAddActivityDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.addNewActivity, style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Racing Simulator, Billiards',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.mutedBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel)),
          AppButton(
            text: AppStrings.saveChanges,
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final newActivity = await widget.categoryCubit.addActivityType(
                  controller.text.toLowerCase().replaceAll(' ', '_'),
                  controller.text,
                );
                if (newActivity != null) {
                  setState(() {
                    _selectedActivityIds.add(newActivity.id);
                  });
                }
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
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
