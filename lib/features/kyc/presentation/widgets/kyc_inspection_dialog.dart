import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_cached_image.dart';
import '../../domain/entities/kyc_request.dart';
import '../cubit/kyc_cubit.dart';

class KycInspectionDialog extends StatelessWidget {
  final KycRequest request;
  final KycCubit cubit;

  const KycInspectionDialog({
    super.key,
    required this.request,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 1000.w,
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.heading(AppStrings.kycInspection, fontSize: 24.sp),
                    SizedBox(height: 4.h),
                    AppText.body("${AppStrings.reviewDocumentsFor} ${request.ownerName} - ${request.loungeName}"),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document Previews
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDocumentSection(context, AppStrings.idCardImage, request.idDocumentUrl),
                          if (request.businessDocumentUrl != null) ...[
                            SizedBox(height: 24.h),
                            _buildDocumentSection(context, AppStrings.businessDocImage, request.businessDocumentUrl ?? ''),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 32.w),
                  // Sidebar Details & Actions
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.subHeading(AppStrings.ownerDetails, fontSize: 16.sp),
                          SizedBox(height: 16.h),
                          _buildDetailRow(Icons.person_outline, AppStrings.fullName, request.ownerName),
                          _buildDetailRow(Icons.email_outlined, AppStrings.email, request.ownerEmail),
                          if (request.ownerPhone.isNotEmpty)
                            _buildDetailRow(Icons.phone_outlined, AppStrings.phoneNumber, request.ownerPhone),
                          _buildDetailRow(Icons.business_outlined, AppStrings.lounges, request.loungeName),
                          
                          const Spacer(),
                          const Divider(color: AppColors.borderDefault),
                          SizedBox(height: 16.h),
                          
                          AppText.body(AppStrings.decisionStatus, fontWeight: FontWeight.bold),
                          SizedBox(height: 16.h),
                          AppButton(
                            text: AppStrings.approve,
                            onPressed: () {
                              cubit.reviewKyc(userId: request.userId, approve: true);
                              Navigator.pop(context);
                            },
                            variant: AppButtonVariant.primary,
                            width: double.infinity,
                          ),
                          SizedBox(height: 12.h),
                          AppButton(
                            text: AppStrings.reject,
                            onPressed: () => _showRejectionDialog(context),
                            variant: AppButtonVariant.outlined,
                            width: double.infinity,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSection(BuildContext context, String title, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(title, fontSize: 14.sp, color: AppColors.neonBlue),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: () => _showFullscreenImage(context, url),
          child: Container(
            width: double.infinity,
            height: 400.h,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            clipBehavior: Clip.antiAlias,
            child: AppCachedImage(
              imageUrl: url,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 16.r, color: AppColors.textSecondary),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.body(label, fontSize: 10.sp, color: AppColors.textSecondary),
                AppText.body(value, fontWeight: FontWeight.bold, fontSize: 13.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(40.r),
        child: InteractiveViewer(
          child: AppCachedImage(imageUrl: url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  void _showRejectionDialog(BuildContext context) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: AppText.heading("Reject KYC Submission", fontSize: 18.sp),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.body("Please provide an optional reason or note for rejecting this KYC application:"),
            SizedBox(height: 12.h),
            TextField(
              controller: notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Reason for rejection (e.g. Blurry document, expired ID...)",
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ],
        ),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.outlined,
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          AppButton(
            text: AppStrings.reject,
            variant: AppButtonVariant.danger,
            onPressed: () {
              cubit.reviewKyc(
                userId: request.userId,
                approve: false,
                notes: notesController.text.trim(),
              );
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
