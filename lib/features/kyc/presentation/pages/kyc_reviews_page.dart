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
import '../widgets/kyc_inspection_dialog.dart';

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
                  return Center(child: AppText.body(state.errorMessage ?? AppStrings.error, color: AppColors.danger));
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
        AppText.body(AppStrings.kycHeaderDesc),
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
          AppText.body(AppStrings.noKycPending, fontSize: 18.sp),
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
      columns: [
        AppStrings.ownerName,
        AppStrings.loungeName,
        AppStrings.idCard,
        AppStrings.businessDoc,
        AppStrings.actions,
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
            AppButton(
              text: AppStrings.viewDocument,
              icon: Icons.visibility_outlined,
              variant: AppButtonVariant.text,
              onPressed: () => _showInspection(context, req, cubit),
            ),
          ),
          DataCell(
            req.businessDocumentUrl != null
              ? AppButton(
                  text: AppStrings.viewDocument,
                  icon: Icons.visibility_outlined,
                  variant: AppButtonVariant.text,
                  onPressed: () => _showInspection(context, req, cubit),
                )
              : const Text('-'),
          ),
          DataCell(
            AppButton(
              text: AppStrings.kycInspection,
              onPressed: () => _showInspection(context, req, cubit),
              variant: AppButtonVariant.primary,
              width: 160.w,
              height: 36.h,
              icon: Icons.fact_check_outlined,
            ),
          ),
        ],
      )).toList(),
    );
  }

  void _showInspection(BuildContext context, KycRequest request, KycCubit cubit) {
    showDialog(
      context: context,
      builder: (context) => KycInspectionDialog(request: request, cubit: cubit),
    );
  }
}
