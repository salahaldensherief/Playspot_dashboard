import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

class PromoFormSection extends StatelessWidget {
  final String selectedDeepLink;
  final Function(String?) onDeepLinkChanged;
  final DateTime? expiresAt;
  final Function(DateTime) onDateChanged;
  final String? selectedTag;
  final Function(String?) onTagChanged;
  final bool isRoomSpecific;
  final Function(bool) onRoomSpecificChanged;
  final String? selectedRoomId;
  final Function(String?) onRoomChanged;
  final String targetAudience;
  final Function(String) onTargetAudienceChanged;
  final List<RoomEntity> availableRooms;
  final TextEditingController titleArController;
  final TextEditingController titleEnController;
  final TextEditingController expirationDateController;

  const PromoFormSection({
    super.key,
    required this.selectedDeepLink,
    required this.onDeepLinkChanged,
    this.expiresAt,
    required this.onDateChanged,
    this.selectedTag,
    required this.onTagChanged,
    required this.isRoomSpecific,
    required this.onRoomSpecificChanged,
    this.selectedRoomId,
    required this.onRoomChanged,
    required this.targetAudience,
    required this.onTargetAudienceChanged,
    required this.availableRooms,
    required this.titleArController,
    required this.titleEnController,
    required this.expirationDateController,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'بيانات العرض الترويجي (Promotion Details)',
      children: [
        // 1. Target Scope (Lounge-wide vs Room-Specific)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.subHeading('نطاق العرض الترويجي:', fontSize: 13.sp, color: AppColors.textPrimary),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => onRoomSpecificChanged(false),
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: !isRoomSpecific ? AppColors.neonPurple.withValues(alpha: 0.15) : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: !isRoomSpecific ? AppColors.neonPurple : AppColors.borderDefault,
                          width: !isRoomSpecific ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront_rounded, size: 18.r, color: !isRoomSpecific ? AppColors.neonPurple : AppColors.textMuted),
                          SizedBox(width: 8.w),
                          AppText.body(
                            'الصالة بالكامل',
                            fontSize: 12.sp,
                            color: !isRoomSpecific ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: !isRoomSpecific ? FontWeight.bold : FontWeight.normal,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: InkWell(
                    onTap: () => onRoomSpecificChanged(true),
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: isRoomSpecific ? AppColors.neonBlue.withValues(alpha: 0.15) : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isRoomSpecific ? AppColors.neonBlue : AppColors.borderDefault,
                          width: isRoomSpecific ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_esports_rounded, size: 18.r, color: isRoomSpecific ? AppColors.neonBlue : AppColors.textMuted),
                          SizedBox(width: 8.w),
                          AppText.body(
                            'روم / جهاز معين',
                            fontSize: 12.sp,
                            color: isRoomSpecific ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: isRoomSpecific ? FontWeight.bold : FontWeight.normal,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Animated Room Dropdown Selector if Room-Specific is enabled
            if (isRoomSpecific) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.4)),
                ),
                child: CustomDropdown<String>(
                  label: AppStrings.selectRoom,
                  value: selectedRoomId,
                  items: availableRooms.map((room) => room.id).toList(),
                  itemLabel: (id) {
                    final room = availableRooms.cast<RoomEntity?>().firstWhere(
                          (r) => r?.id == id,
                          orElse: () => null,
                        );
                    if (room == null) return AppStrings.selectRoom;
                    final name = room.nameAr.isNotEmpty ? room.nameAr : (room.nameEn.isNotEmpty ? room.nameEn : 'Gaming Room');
                    return room.controllersCount > 0 ? '$name (${room.controllersCount} دراعات)' : name;
                  },
                  onChanged: onRoomChanged,
                  validator: (v) => isRoomSpecific && v == null ? AppStrings.fieldRequired : null,
                ),
              ),
            ],
          ],
        ),

        SizedBox(height: 16.h),

        // 2. Titles (Arabic & English)
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: titleArController,
                label: AppStrings.promoTitleAr,
                hintText: AppStrings.promoTitleArHint,
                validator: AppValidator.validateRequired,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: AppTextField(
                controller: titleEnController,
                label: AppStrings.promoTitleEn,
                hintText: AppStrings.promoTitleEnHint,
                validator: AppValidator.validateRequired,
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // 3. Tag Category & Expiration Date
        Row(
          children: [
            Expanded(
              child: CustomDropdown<String>(
                label: AppStrings.tagCategory,
                value: selectedTag,
                items: const [
                  'خصم 50%',
                  'خصم 20%',
                  'خصم 10%',
                  'عرض خاص',
                  'عرض الويكيند',
                  'حدث / بطولة',
                  'عرض جديد',
                ],
                itemLabel: (s) => s,
                onChanged: onTagChanged,
                validator: (v) => v == null ? AppStrings.fieldRequired : null,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: expiresAt ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) onDateChanged(date);
                },
                borderRadius: BorderRadius.circular(8.r),
                child: IgnorePointer(
                  child: AppTextField(
                    label: AppStrings.expirationDate,
                    hintText: 'YYYY-MM-DD',
                    controller: expirationDateController,
                    prefixIcon: Icons.calendar_month_rounded,
                    validator: AppValidator.validateRequired,
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // 4. Target Audience (Local vs All)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.subHeading('الجمهور المستهدف (Audience):', fontSize: 13.sp, color: AppColors.textPrimary),
            SizedBox(height: 8.h),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'local',
                  label: Text('📍 عملاء الصالة المحليين'),
                ),
                ButtonSegment(
                  value: 'all',
                  label: Text('🌐 جميع مستخدمي التطبيق'),
                ),
              ],
              selected: {targetAudience},
              onSelectionChanged: (Set<String> newSelection) {
                onTargetAudienceChanged(newSelection.first);
              },
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // 5. Deep Link Destination
        CustomDropdown<String>(
          label: AppStrings.deepLinkDest,
          value: selectedDeepLink,
          items: const ['Specific Room', 'Lounge Profile', 'External Link', '/offers'],
          itemLabel: (s) => s,
          onChanged: onDeepLinkChanged,
        ),
      ],
    );
  }
}
