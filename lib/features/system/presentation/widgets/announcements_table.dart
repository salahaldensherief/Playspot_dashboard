import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' as intl;
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import '../../domain/entities/announcement_entity.dart';

class AnnouncementsTable extends StatelessWidget {
  final List<AnnouncementEntity> announcements;
  final ValueChanged<String> onDeactivate;

  const AnnouncementsTable({
    super.key,
    required this.announcements,
    required this.onDeactivate,
  });

  String _formatAudience(AnnouncementEntity a) {
    if (a.targetAudience == 'all') return AppStrings.audienceAll;
    if (a.targetAudience == 'lounge_owners') return AppStrings.audienceOwners;
    if (a.targetAudience == 'specific_lounge') {
      return a.targetLoungeName != null && a.targetLoungeName!.isNotEmpty
          ? '${AppStrings.audienceSpecificLounge}: ${a.targetLoungeName}'
          : AppStrings.audienceSpecificLounge;
    }
    return a.targetAudience;
  }

  StatusBadge _buildTypeBadge(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return StatusBadge.warning(AppStrings.typeWarning);
      case 'update':
        return StatusBadge.secondary(AppStrings.typeUpdate);
      case 'info':
      default:
        return StatusBadge.info(AppStrings.typeInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: AppStrings.announcementsLog,
      children: [
        if (announcements.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.campaign_outlined, color: AppColors.textMuted, size: 48.r),
                SizedBox(height: 12.h),
                Text(
                  AppStrings.noAnnouncementsFound,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                ),
              ],
            ),
          )
        else
          DataTableWidget(
            columns: [
              AppStrings.targetAudience,
              AppStrings.announcementTitleAr,
              AppStrings.announcementType,
              AppStrings.status,
              AppStrings.date,
              AppStrings.actions,
            ],
            rows: announcements.map((announcement) {
              final formattedDate = intl.DateFormat('yyyy/MM/dd - hh:mm a').format(announcement.createdAt);

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      _formatAudience(announcement),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.titleAr,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (announcement.titleEn.isNotEmpty)
                          Text(
                            announcement.titleEn,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  DataCell(_buildTypeBadge(announcement.type)),
                  DataCell(
                    announcement.isActive
                        ? StatusBadge.success(AppStrings.active)
                        : StatusBadge.neutral(AppStrings.inactive),
                  ),
                  DataCell(
                    Text(
                      formattedDate,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                    ),
                  ),
                  DataCell(
                    announcement.isActive
                        ? AppButton(
                            text: AppStrings.deactivate,
                            variant: AppButtonVariant.outlined,
                            foregroundColor: AppColors.danger,
                            fontSize: 11.sp,
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            onPressed: () => onDeactivate(announcement.id),
                          )
                        : Text(
                            AppStrings.completed,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }
}
