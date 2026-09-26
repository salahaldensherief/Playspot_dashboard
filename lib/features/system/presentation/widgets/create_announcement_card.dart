import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import '../../domain/entities/announcement_entity.dart';
import 'audience_option_chip.dart';
import 'type_option_chip.dart';

class CreateAnnouncementCard extends StatefulWidget {
  final List<Lounge> lounges;
  final bool isLoading;
  final ValueChanged<AnnouncementEntity> onSubmit;

  const CreateAnnouncementCard({
    super.key,
    required this.lounges,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  State<CreateAnnouncementCard> createState() => _CreateAnnouncementCardState();
}

class _CreateAnnouncementCardState extends State<CreateAnnouncementCard> {
  final _formKey = GlobalKey<FormState>();
  String _targetAudience = 'all';
  Lounge? _selectedLounge;
  String _announcementType = 'info';
  bool _isSubmitting = false;

  final TextEditingController _titleArController = TextEditingController();
  final TextEditingController _titleEnController = TextEditingController();
  final TextEditingController _bodyArController = TextEditingController();
  final TextEditingController _bodyEnController = TextEditingController();

  @override
  void dispose() {
    _titleArController.dispose();
    _titleEnController.dispose();
    _bodyArController.dispose();
    _bodyEnController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || widget.isLoading) return;

    if (_formKey.currentState!.validate()) {
      if (_targetAudience == 'specific_lounge' && _selectedLounge == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.selectTargetLoungeError),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      final title = _titleArController.text.trim();
      final body = _bodyArController.text.trim();

      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Icon(Icons.campaign_outlined, color: AppColors.warning, size: 28.r),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'تأكيد إرسال الإعلان الجماعي',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هل أنت متاكد من نشر هذا الإعلان وتنبيه جميع المستخدمين المستهدفين عبر Push Notifications؟',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.mutedBackground,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('العنوان: $title', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                    SizedBox(height: 4.h),
                    Text('المحتوى: $body', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonBlue),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('تأكيد الإرسال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _isSubmitting = true);

      try {
        final announcement = AnnouncementEntity(
          id: '',
          targetAudience: _targetAudience,
          targetLoungeId: _targetAudience == 'specific_lounge' ? _selectedLounge?.id : null,
          targetLoungeName: _targetAudience == 'specific_lounge' ? _selectedLounge?.name : null,
          titleAr: _titleArController.text.trim(),
          titleEn: _titleEnController.text.trim(),
          bodyAr: _bodyArController.text.trim(),
          bodyEn: _bodyEnController.text.trim(),
          type: _announcementType,
          isActive: true,
          createdAt: DateTime.now(),
        );

        widget.onSubmit(announcement);

        _titleArController.clear();
        _titleEnController.clear();
        _bodyArController.clear();
        _bodyEnController.clear();
        if (mounted) {
          setState(() {
            _targetAudience = 'all';
            _selectedLounge = null;
            _announcementType = 'info';
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: AppStrings.createAnnouncement,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.targetAudience,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: AudienceOptionChip(
                      label: AppStrings.audienceAll,
                      icon: Icons.groups_outlined,
                      isSelected: _targetAudience == 'all',
                      onTap: () => setState(() {
                        _targetAudience = 'all';
                        _selectedLounge = null;
                      }),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AudienceOptionChip(
                      label: AppStrings.audienceOwners,
                      icon: Icons.storefront_outlined,
                      isSelected: _targetAudience == 'lounge_owners',
                      onTap: () => setState(() {
                        _targetAudience = 'lounge_owners';
                        _selectedLounge = null;
                      }),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AudienceOptionChip(
                      label: AppStrings.audienceSpecificLounge,
                      icon: Icons.business,
                      isSelected: _targetAudience == 'specific_lounge',
                      onTap: () => setState(() => _targetAudience = 'specific_lounge'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              if (_targetAudience == 'specific_lounge') ...[
                CustomDropdown<Lounge>(
                  label: AppStrings.selectTargetLounge,
                  value: _selectedLounge,
                  items: widget.lounges,
                  itemLabel: (lounge) => lounge.name,
                  onChanged: (lounge) => setState(() => _selectedLounge = lounge),
                ),
                SizedBox(height: 16.h),
              ],

              Text(
                AppStrings.announcementType,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  TypeOptionChip(
                    label: AppStrings.typeInfo,
                    color: AppColors.neonBlue,
                    isSelected: _announcementType == 'info',
                    onTap: () => setState(() => _announcementType = 'info'),
                  ),
                  SizedBox(width: 12.w),
                  TypeOptionChip(
                    label: AppStrings.typeWarning,
                    color: AppColors.warning,
                    isSelected: _announcementType == 'warning',
                    onTap: () => setState(() => _announcementType = 'warning'),
                  ),
                  SizedBox(width: 12.w),
                  TypeOptionChip(
                    label: AppStrings.typeUpdate,
                    color: AppColors.neonPurple,
                    isSelected: _announcementType == 'update',
                    onTap: () => setState(() => _announcementType = 'update'),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.announcementTitleAr,
                      hintText: AppStrings.announcementTitleArHint,
                      controller: _titleArController,
                      validator: (val) => val == null || val.trim().isEmpty ? AppStrings.fieldRequired : null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.announcementTitleEn,
                      hintText: AppStrings.announcementTitleEnHint,
                      controller: _titleEnController,
                      validator: (val) => val == null || val.trim().isEmpty ? AppStrings.fieldRequired : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.announcementBodyAr,
                      hintText: AppStrings.announcementBodyArHint,
                      controller: _bodyArController,
                      maxLines: 3,
                      validator: (val) => val == null || val.trim().isEmpty ? AppStrings.fieldRequired : null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.announcementBodyEn,
                      hintText: AppStrings.announcementBodyEnHint,
                      controller: _bodyEnController,
                      maxLines: 3,
                      validator: (val) => val == null || val.trim().isEmpty ? AppStrings.fieldRequired : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AppButton(
                  text: AppStrings.publishAnnouncementBtn,
                  icon: Icons.campaign_outlined,
                  isLoading: widget.isLoading,
                  variant: AppButtonVariant.gradient,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
