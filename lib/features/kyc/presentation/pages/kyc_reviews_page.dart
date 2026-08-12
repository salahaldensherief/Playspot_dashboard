import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import '../../domain/entities/kyc_request.dart';
import '../cubit/kyc_cubit.dart';
import '../cubit/kyc_state.dart';
import 'package:url_launcher/url_launcher.dart';

class KycReviewsPage extends StatelessWidget {
  const KycReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final kycCubit = context.read<KycCubit>();

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 32.h),
          Expanded(
            child: BlocBuilder<KycCubit, KycState>(
              bloc: kycCubit,
              builder: (context, state) {
                if (state.status == KycStatus.loading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
                }
                if (state.status == KycStatus.failure) {
                  return Center(child: AppText.body(state.errorMessage ?? 'Error', color: AppColors.danger));
                }
                if (state.requests.isEmpty) {
                  return _buildEmptyState();
                }
                return _KycDataTable(requests: state.requests, cubit: kycCubit);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.heading(AppStrings.kycReviews, fontSize: 32.sp),
        SizedBox(height: 8.h),
        AppText.body('Review and verify documents submitted by lounge owners.'),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.textSecondary, size: 64.r),
          SizedBox(height: 16.h),
          AppText.body('No pending KYC reviews at the moment.', fontSize: 18.sp),
        ],
      ),
    );
  }
}

class _KycDataTable extends StatelessWidget {
  final List<KycRequest> requests;
  final KycCubit cubit;
  const _KycDataTable({required this.requests, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return DataTableWidget(
      columns: const [
        'Owner Name',
        'Lounge Name',
        'ID Card',
        'Business Doc',
        'Actions',
      ],
      rows: requests.map((req) => DataRow(
        cells: [
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText.body(req.ownerName, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                AppText.body(req.ownerEmail, color: AppColors.textSecondary, fontSize: 11.sp),
              ],
            ),
          ),
          DataCell(AppText.body(req.loungeName)),
          DataCell(
            TextButton.icon(
              onPressed: () => _openUrl(req.idDocumentUrl),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: Text(AppStrings.viewDocument),
            ),
          ),
          DataCell(
            req.businessDocumentUrl != null
              ? TextButton.icon(
                  onPressed: () => _openUrl(req.businessDocumentUrl!),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: Text(AppStrings.viewDocument),
                )
              : const Text('-'),
          ),
          DataCell(
            Row(
              children: [
                AppButton(
                  text: AppStrings.approve,
                  onPressed: () => cubit.reviewKyc(userId: req.userId, approve: true),
                  variant: AppButtonVariant.primary,
                  width: 100.w,
                ),
                SizedBox(width: 8.w),
                AppButton(
                  text: AppStrings.reject,
                  onPressed: () => cubit.reviewKyc(userId: req.userId, approve: false),
                  variant: AppButtonVariant.outlined,
                  width: 100.w,
                ),
              ],
            ),
          ),
        ],
      )).toList(),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
