import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/marketing/presentation/cubit/marketing_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';
import '../../domain/entities/promo_entity.dart';
import 'promo_form_section.dart';
import 'design_style_section.dart';

class PromoDialog extends StatefulWidget {
  final PromoEntity promo;
  final Function(PromoEntity)? onSave;

  const PromoDialog({super.key, required this.promo, this.onSave});

  @override
  State<PromoDialog> createState() => _PromoDialogState();
}

class _PromoDialogState extends State<PromoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleArController;
  late TextEditingController _titleEnController;
  late TextEditingController _expirationDateController;
  
  final List<List<Color>> _colorTemplates = [
    [AppColors.neonPurple, AppColors.neonBlue],
    [Colors.orange, Colors.red],
    [Colors.green, Colors.teal],
    [Colors.blue, Colors.indigo],
  ];

  int _selectedTemplate = 0;
  String _selectedIcon = 'Flash';
  String _selectedDeepLink = 'Specific Room';
  DateTime? _expiresAt;
  String? _selectedTag;
  bool _isRoomSpecific = false;
  String? _selectedRoomId;
  String _targetAudience = 'all';
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _currentImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _titleArController = TextEditingController(text: widget.promo.titleAr);
    _titleEnController = TextEditingController(text: widget.promo.titleEn);
    _expirationDateController = TextEditingController(
      text: widget.promo.expiresAt?.toLocal().toString().split(' ')[0] ?? '',
    );
    _selectedIcon = widget.promo.iconKey;
    _selectedDeepLink = widget.promo.deepLink ?? 'Specific Room';
    _expiresAt = widget.promo.expiresAt;
    _selectedTag = widget.promo.tag;
    _isRoomSpecific = widget.promo.isRoomSpecific;
    _selectedRoomId = widget.promo.roomId;
    _targetAudience = widget.promo.targetAudience;
    _currentImageUrl = widget.promo.imageUrl;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _selectedImageBytes = result.files.first.bytes;
        _selectedImageName = result.files.first.name;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);
      
      String? imageUrl = _currentImageUrl;
      if (_selectedImageBytes != null) {
        imageUrl = await context.read<MarketingCubit>().uploadPromoPoster(
          _selectedImageBytes!,
          _selectedImageName!,
        );
      }

      if (widget.onSave != null) {
        final updatedPromo = PromoEntity(
          id: widget.promo.id,
          titleAr: _titleArController.text,
          titleEn: _titleEnController.text,
          tagAr: _selectedTag ?? '',
          tagEn: _selectedTag ?? '',
          hexColors: _colorTemplates[_selectedTemplate].map((e) => '#${e.value.toRadixString(16).substring(2)}').toList(),
          iconKey: _selectedIcon,
          deepLink: _selectedDeepLink,
          expiresAt: _expiresAt,
          tag: _selectedTag,
          isRoomSpecific: _isRoomSpecific,
          loungeId: widget.promo.loungeId,
          roomId: _selectedRoomId,
          targetAudience: _targetAudience,
          imageUrl: imageUrl,
        );
        widget.onSave!(updatedPromo);
      }
      setState(() => _isUploading = false);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomCubit, RoomState>(
      builder: (context, roomState) {
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
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: PromoFormSection(
                            titleArController: _titleArController,
                            titleEnController: _titleEnController,
                            expirationDateController: _expirationDateController,
                            selectedDeepLink: _selectedDeepLink,
                            onDeepLinkChanged: (v) => setState(() => _selectedDeepLink = v ?? 'Specific Room'),
                            expiresAt: _expiresAt,
                            onDateChanged: (v) => setState(() {
                              _expiresAt = v;
                              _expirationDateController.text = v.toLocal().toString().split(' ')[0];
                            }),
                            selectedTag: _selectedTag,
                            onTagChanged: (v) => setState(() => _selectedTag = v),
                            isRoomSpecific: _isRoomSpecific,
                            onRoomSpecificChanged: (v) => setState(() => _isRoomSpecific = v),
                            selectedRoomId: _selectedRoomId,
                            onRoomChanged: (v) => setState(() => _selectedRoomId = v),
                            targetAudience: _targetAudience,
                            onTargetAudienceChanged: (v) => setState(() => _targetAudience = v),
                            availableRooms: roomState.rooms,
                          ),
                        ),
                        SizedBox(width: 32.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.promoPoster,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  height: 300.h,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.mutedBackground,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(color: AppColors.borderDefault),
                                    image: (_selectedImageBytes != null)
                                        ? DecorationImage(
                                            image: MemoryImage(_selectedImageBytes!),
                                            fit: BoxFit.cover,
                                          )
                                        : (_currentImageUrl != null)
                                            ? DecorationImage(
                                                image: NetworkImage(_currentImageUrl!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                  ),
                                  child: (_selectedImageBytes == null && _currentImageUrl == null)
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate_outlined, size: 48.r, color: AppColors.textSecondary),
                                            SizedBox(height: 8.h),
                                            Text(AppStrings.uploadPoster, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
                                          ],
                                        )
                                      : Align(
                                          alignment: Alignment.topRight,
                                          child: IconButton(
                                            onPressed: () => setState(() {
                                              _selectedImageBytes = null;
                                              _currentImageUrl = null;
                                            }),
                                            icon: Container(
                                              padding: EdgeInsets.all(4.r),
                                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              if (_selectedImageBytes != null || _currentImageUrl != null) ...[
                                SizedBox(height: 12.h),
                                AppButton(
                                  text: AppStrings.changePoster,
                                  onPressed: _pickImage,
                                  variant: AppButtonVariant.outlined,
                                  height: 36.h,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    DesignStyleSection(
                      colorTemplates: _colorTemplates,
                      selectedTemplate: _selectedTemplate,
                      onTemplateSelected: (index) => setState(() => _selectedTemplate = index),
                      selectedIcon: _selectedIcon,
                      onIconChanged: (v) => setState(() => _selectedIcon = v ?? 'Flash'),
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
                          text: AppStrings.saveChanges,
                          onPressed: _isUploading ? null : _submit,
                          isLoading: _isUploading,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
