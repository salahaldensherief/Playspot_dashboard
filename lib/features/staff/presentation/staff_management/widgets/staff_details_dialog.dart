import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/staff/domain/entities/staff_entity.dart';

import '../../../../../art_core/widgets/app_avatar.dart';
import '../../../../../art_core/widgets/app_cached_image.dart';
import '../../../../../art_core/widgets/app_dialog.dart';

class StaffDetailsDialog extends StatelessWidget {
  final StaffEntity staff;

  const StaffDetailsDialog({super.key, required this.staff});

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return AppDialog(
      title: staff.name,
      icon: Icons.badge_outlined,
      width: 600.w,
      actions: [
        AppButton(
          text: AppStrings.close,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                radius: 24.r,
                imageUrl: staff.avatarUrl,
                backgroundColor: AppColors.neonBlue.withValues(alpha: 0.1),
                fallback: Icon(
                  Icons.person,
                  color: AppColors.neonBlue,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.subHeading(staff.name, fontSize: 16.sp, maxLines: 1),
                    SizedBox(height: 4.h),
                    _buildRoleBadge(staff.role),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          const Divider(color: AppColors.borderDefault),
          SizedBox(height: 12.h),

          _buildSectionTitle(
            Icons.contact_mail_outlined,
            AppStrings.contactLabel,
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            Icons.email_outlined,
            AppStrings.email,
            staff.email,
          ),
          _buildInfoRow(
            Icons.phone_android_outlined,
            AppStrings.staffPhone,
            staff.phone ?? 'N/A',
          ),

          const Divider(color: AppColors.borderDefault),
          SizedBox(height: 8.h),

          _buildSectionTitle(
            Icons.badge_outlined,
            AppStrings.nationalIdentityDetails,
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            Icons.numbers_outlined,
            AppStrings.nationalIdNumber,
            staff.nationalIdNumber ?? 'N/A',
          ),

          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildIdCardPreview(
                  context,
                  AppStrings.idFront,
                  staff.idFrontUrl,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildIdCardPreview(
                  context,
                  AppStrings.idBack,
                  staff.idBackUrl,
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),
          const Divider(color: AppColors.borderDefault),
          SizedBox(height: 8.h),

          _buildSectionTitle(
            Icons.history_outlined,
            AppStrings.shiftHistory,
          ),
          SizedBox(height: 8.h),
          AppText.body(
            '${AppStrings.memberSince} ${DateFormat('MMM yyyy').format(staff.createdAt)}',
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18.r, color: AppColors.neonBlue),
        SizedBox(width: 8.w),
        AppText.subHeading(
          title,
          fontSize: 14.sp,
          color: AppColors.textPrimary,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 14.r, color: AppColors.textSecondary),
          SizedBox(width: 8.w),
          AppText.body("$label: ", color: AppColors.textSecondary),
          AppText.body(
            value,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildIdCardPreview(BuildContext context, String label, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(label, fontSize: 12.sp, color: AppColors.textSecondary),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: url != null ? () => _showFullscreenImage(context, url) : null,
          child: Container(
            height: 120.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            clipBehavior: Clip.antiAlias,
            child: url != null
                ? AppCachedImage(imageUrl: url, fit: BoxFit.cover)
                : const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _showFullscreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(40.r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(child: AppCachedImage(imageUrl: url)),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textPrimary,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final cleanRole = role.toLowerCase().trim();
    if (cleanRole == 'owner' ||
        cleanRole == 'lounge_owner' ||
        cleanRole == 'lounge_admin') {
      return StatusBadge.secondary(AppStrings.loungeOwnerLabel);
    }
    if (cleanRole == 'manager') {
      return StatusBadge.secondary(AppStrings.manager);
    }
    if (cleanRole == 'super_admin' || cleanRole == 'superadmin') {
      return StatusBadge.secondary(AppStrings.superAdmin);
    }
    return StatusBadge.info(AppStrings.cashierLabel);
  }
}
