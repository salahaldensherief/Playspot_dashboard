import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
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
  }

  @override
  void dispose() {
    _titleArController.dispose();
    _titleEnController.dispose();
    _expirationDateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (widget.onSave != null) {
        final updatedPromo = PromoEntity(
          id: widget.promo.id,
          titleAr: _titleArController.text,
          titleEn: _titleEnController.text,
          tagAr: _selectedTag ?? '', // Or keep old ones if they are separate
          tagEn: _selectedTag ?? '',
          hexColors: _colorTemplates[_selectedTemplate].map((e) => '#${e.value.toRadixString(16).substring(2)}').toList(),
          iconKey: _selectedIcon,
          deepLink: _selectedDeepLink,
          expiresAt: _expiresAt,
          tag: _selectedTag,
          isRoomSpecific: _isRoomSpecific,
          loungeId: widget.promo.loungeId,
          roomId: _selectedRoomId,
        );
        widget.onSave!(updatedPromo);
      }
      Navigator.pop(context);
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
            width: 600.w,
            padding: EdgeInsets.all(32.r),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PromoFormSection(
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
                      availableRooms: roomState.rooms,
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
      },
    );
  }
}
