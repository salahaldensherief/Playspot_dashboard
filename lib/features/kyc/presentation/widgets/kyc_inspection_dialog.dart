import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
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
                    AppText.heading("KYC Inspection", fontSize: 24.sp),
                    SizedBox(height: 4.h),
                    AppText.body("Review documents for ${request.ownerName} - ${request.loungeName}"),
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
                          _buildDocumentSection(context, "Identity Document (Front/Back)", request.idDocumentUrl),
                          if (request.businessDocumentUrl != null) ...[
                            SizedBox(height: 24.h),
                            _buildDocumentSection(context, "Business Document / Commercial License", request.businessDocumentUrl!),
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
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.subHeading("Owner Details", fontSize: 16.sp),
                          SizedBox(height: 16.h),
                          _buildDetailRow(Icons.person_outline, "Name", request.ownerName),
                          _buildDetailRow(Icons.email_outlined, "Email", request.ownerEmail),
                          _buildDetailRow(Icons.business_outlined, "Lounge", request.loungeName),
                          
                          const Spacer(),
                          const Divider(color: AppColors.borderDefault),
                          SizedBox(height: 16.h),
                          
                          AppText.body("Decision Status", fontWeight: FontWeight.bold),
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
                            onPressed: () {
                              cubit.reviewKyc(userId: request.userId, approve: false);
                              Navigator.pop(context);
                            },
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
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) => progress == null 
                  ? child 
                  : const Center(child: CircularProgressIndicator()),
              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: AppColors.danger)),
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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(40.r),
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }
}
