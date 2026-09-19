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
  String _targetAudience = 'all'; // 'all', 'lounge_owners', 'specific_lounge'
  Lounge? _selectedLounge;
  String _announcementType = 'info'; // 'info', 'warning', 'update'

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

  void _submit() {
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

      // Reset form on submission
      _titleArController.clear();
      _titleEnController.clear();
      _bodyArController.clear();
      _bodyEnController.clear();
      setState(() {
        _targetAudience = 'all';
        _selectedLounge = null;
        _announcementType = 'info';
      });
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
              // Target Audience selection
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
                    child: _AudienceOptionChip(
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
                    child: _AudienceOptionChip(
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
                    child: _AudienceOptionChip(
                      label: AppStrings.audienceSpecificLounge,
                      icon: Icons.business,
                      isSelected: _targetAudience == 'specific_lounge',
                      onTap: () => setState(() => _targetAudience = 'specific_lounge'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Specific Lounge Selector if specific_lounge
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

              // Announcement Type Selection
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
                  _TypeOptionChip(
                    label: AppStrings.typeInfo,
                    color: AppColors.neonBlue,
                    isSelected: _announcementType == 'info',
                    onTap: () => setState(() => _announcementType = 'info'),
                  ),
                  SizedBox(width: 12.w),
                  _TypeOptionChip(
                    label: AppStrings.typeWarning,
                    color: AppColors.warning,
                    isSelected: _announcementType == 'warning',
                    onTap: () => setState(() => _announcementType = 'warning'),
                  ),
                  SizedBox(width: 12.w),
                  _TypeOptionChip(
                    label: AppStrings.typeUpdate,
                    color: AppColors.neonPurple,
                    isSelected: _announcementType == 'update',
                    onTap: () => setState(() => _announcementType = 'update'),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Titles in 2 languages
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

              // Body text in 2 languages
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

class _AudienceOptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AudienceOptionChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonBlue.withAlpha(25) : AppColors.mutedBackground,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? AppColors.neonBlue : AppColors.borderDefault,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.r,
              color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.neonBlue : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13.sp,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeOptionChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOptionChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(30) : AppColors.mutedBackground,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? color : AppColors.borderDefault,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }
}
