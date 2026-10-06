import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_multi_image_picker.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:uuid/uuid.dart';
import '../../../categories/presentation/categories/category_cubit.dart';
import '../../domain/entities/room_entity.dart';
import '../cubit/room_cubit.dart';
import 'room_basic_info_form.dart';
import 'room_features_section.dart';
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
  late TextEditingController _hourlyRateSingleController;
  late TextEditingController _hourlyRateMultiController;
  late TextEditingController _maxCapacityController;
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

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _nameArController = TextEditingController(text: r?.nameAr);
    _nameEnController = TextEditingController(text: r?.nameEn);
    _descriptionArController = TextEditingController(text: r?.descriptionAr);
    _descriptionEnController = TextEditingController(text: r?.descriptionEn);
    _hourlyRateSingleController = TextEditingController(
      text: r?.hourlyRateSingle.toString() ?? '0.0',
    );
    _hourlyRateMultiController = TextEditingController(
      text: r?.hourlyRateMulti.toString() ?? '0.0',
    );
    _maxCapacityController = TextEditingController(
      text: r?.maxCapacity.toString() ?? (r?.isOpenArea == true ? '2' : '4'),
    );
    _controllersController = TextEditingController(
      text: r?.controllersCount.toString() ?? '2',
    );
    _screenSizeController = TextEditingController(text: r?.screenSize ?? '43"');
    _extraPriceController = TextEditingController(
      text: r?.extraControllerPrice.toString() ?? '0.0',
    );

    _selectedSpaceTypeId = r?.spaceTypeId;

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
    _hourlyRateSingleController.dispose();
    _hourlyRateMultiController.dispose();
    _maxCapacityController.dispose();
    _controllersController.dispose();
    _screenSizeController.dispose();
    _extraPriceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isUploading) return;
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      if (_roomImages.isEmpty && (widget.room?.images.isEmpty ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.minImagesError),
            backgroundColor: AppColors.danger,
          ),
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
          final spaceTypes = context.read<RoomCubit>().state.spaceTypes;
          final selectedSpaceTypeId =
              _selectedSpaceTypeId ??
              (spaceTypes.isNotEmpty ? spaceTypes.first.id : null);
          if (selectedSpaceTypeId == null) {
            throw StateError('Room space types are unavailable.');
          }

          final selectedSpaceType = spaceTypes
              .where((type) => type.id == selectedSpaceTypeId)
              .firstOrNull;
          if (selectedSpaceType == null) {
            throw StateError('Selected room space type is no longer available.');
          }

          final isOpenArea = selectedSpaceType.categoryKey == 'open_area';
          final singleRate =
              double.tryParse(_hourlyRateSingleController.text) ?? 0.0;
          final multiRate =
              double.tryParse(_hourlyRateMultiController.text) ?? 0.0;

          final room = RoomEntity(
            id: widget.room?.id ?? const Uuid().v4(),
            loungeId: widget.loungeId,
            nameAr: _nameArController.text,
            nameEn: _nameEnController.text,
            descriptionAr: _descriptionArController.text,
            descriptionEn: _descriptionEnController.text,
            spaceType: selectedSpaceType.name,
            spaceTypeId: selectedSpaceType.id,
            hourlyRateSingle: singleRate,
            hourlyRateMulti: multiRate,
            extraControllerPrice:
                double.tryParse(_extraPriceController.text) ?? 0,
            maxCapacity:
                int.tryParse(_maxCapacityController.text) ??
                (isOpenArea ? 2 : 4),
            controllersCount: isOpenArea
                ? (int.tryParse(_controllersController.text) ?? 2)
                : 2,
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
            SnackBar(
              content: Text('${AppStrings.error}: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final roomState = context.watch<RoomCubit>().state;
    final spaceTypes = roomState.spaceTypes;
    final selectedSpaceType = spaceTypes
        .where((type) => type.id == _selectedSpaceTypeId)
        .firstOrNull;
    final effectiveSpaceTypeId =
        selectedSpaceType?.id ?? (spaceTypes.isNotEmpty ? spaceTypes.first.id : null);
    final effectiveSpaceType =
        selectedSpaceType ?? (spaceTypes.isNotEmpty ? spaceTypes.first : null);
    final isOpenArea = effectiveSpaceType?.categoryKey == 'open_area';

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12.w : 24.w,
        vertical: 24.h,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.r : 32.r),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 32.h),
                if (spaceTypes.isNotEmpty)
                  CustomDropdown<String>(
                    label: AppStrings.spaceType,
                    value: effectiveSpaceTypeId,
                    items: spaceTypes.map((type) => type.id).toList(),
                    itemLabel: (id) => spaceTypes
                        .where((type) => type.id == id)
                        .map((type) => type.label)
                        .firstOrNull ?? id,
                    onChanged: (v) => setState(() => _selectedSpaceTypeId = v),
                  )
                else
                  const LinearProgressIndicator(),
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
                  hourlyRateSingleController: _hourlyRateSingleController,
                  hourlyRateMultiController: _hourlyRateMultiController,
                  isOpenArea: isOpenArea,
                ),
                SizedBox(height: 20.h),
                RoomSpecsForm(
                  capacityController: _maxCapacityController,
                  controllersController: _controllersController,
                  screenSizeController: _screenSizeController,
                  extraPriceController: _extraPriceController,
                  selectedSpaceTypeId: _selectedSpaceTypeId,
                  status: _selectedStatus,
                  onStatusChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedStatus = v);
                    }
                  },
                  featuresEn: _featuresEn,
                  onFeatureChanged: (feature, selected) {
                    setState(() {
                      if (selected) {
                        if (!_featuresEn.contains(feature)) {
                          _featuresEn.add(feature);
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
                RoomFeaturesSection(
                  featuresAr: _featuresAr,
                  featuresEn: _featuresEn,
                  selectedActivityIds: _selectedActivityIds,
                  activitiesList: widget.categoryCubit.state.activityTypes,
                  onAddFeature: (en, ar) => setState(() {
                    _featuresEn.add(en);
                    _featuresAr.add(ar);
                  }),
                  onRemoveFeature: (idx) => setState(() {
                    _featuresEn.removeAt(idx);
                    _featuresAr.removeAt(idx);
                  }),
                  onToggleTag: (tag) => setState(() {
                    if (_featuresEn.contains(tag)) {
                      final idx = _featuresEn.indexOf(tag);
                      _featuresEn.removeAt(idx);
                      _featuresAr.removeAt(idx);
                    } else {
                      _featuresEn.add(tag);
                      _featuresAr.add(tag);
                    }
                  }),
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
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16.w,
      runSpacing: 12.h,
      children: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        AppButton(
          text: widget.room == null
              ? AppStrings.createStation
              : AppStrings.updateStation,
          isLoading: _isUploading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
