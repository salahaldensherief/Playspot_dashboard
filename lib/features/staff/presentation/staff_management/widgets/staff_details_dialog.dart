import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/staff/data/entities/staff_entity.dart';

class StaffDetailsDialog extends StatelessWidget {
  final StaffEntity staff;

  const StaffDetailsDialog({super.key, required this.staff});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: AppColors.neonBlue.withOpacity(0.1),
            backgroundImage: staff.avatarUrl != null ? NetworkImage(staff.avatarUrl!) : null,
            child: staff.avatarUrl == null ? Icon(Icons.person, color: AppColors.neonBlue, size: 20.r) : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: AppText.subHeading(staff.name, fontSize: 18.sp, maxLines: 1),
          ),
          _buildRoleBadge(staff.role),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600.r),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(Icons.contact_mail_outlined, AppStrings.contactLabel),
              SizedBox(height: 12.h),
              _buildInfoRow(Icons.email_outlined, AppStrings.email, staff.email),
              _buildInfoRow(Icons.phone_android_outlined, AppStrings.staffPhone, staff.phone ?? 'N/A'),
              
              const Divider(color: AppColors.borderDefault),
              SizedBox(height: 8.h),
              
              _buildSectionTitle(Icons.badge_outlined, "National Identity Details"),
              SizedBox(height: 12.h),
              _buildInfoRow(Icons.numbers_outlined, "National ID Number", staff.nationalIdNumber ?? 'N/A'),
              
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(child: _buildIdCardPreview(context, "ID Front", staff.idFrontUrl)),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildIdCardPreview(context, "ID Back", staff.idBackUrl)),
                ],
              ),
              
              SizedBox(height: 24.h),
              const Divider(color: AppColors.borderDefault),
              SizedBox(height: 8.h),
              
              _buildSectionTitle(Icons.history_outlined, AppStrings.shiftHistory),
              SizedBox(height: 8.h),
              AppText.body("Member since ${DateFormat('MMM yyyy').format(staff.createdAt)}", color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          text: AppStrings.close,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18.r, color: AppColors.neonBlue),
        SizedBox(width: 8.w),
        AppText.subHeading(title, fontSize: 14.sp, color: AppColors.textPrimary),
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
          AppText.body(value, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
              ? Image.network(
                  url, 
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.danger)),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                )
              : const Center(child: Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary)),
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
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(url),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    if (role == 'lounge_owner') return StatusBadge.secondary(AppStrings.manager);
    if (role == 'manager') return StatusBadge.secondary(AppStrings.manager);
    return StatusBadge.info(AppStrings.cashierLabel);
  }
}
