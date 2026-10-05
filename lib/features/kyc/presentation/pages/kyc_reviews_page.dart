import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_adaptive_page_header.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import '../../domain/entities/kyc_request.dart';
import '../cubit/kyc_cubit.dart';
import '../cubit/kyc_state.dart';
import '../widgets/kyc_inspection_dialog.dart';

class KycReviewsPage extends StatefulWidget {
  const KycReviewsPage({super.key});

  @override
  State<KycReviewsPage> createState() => _KycReviewsPageState();
}

class _KycReviewsPageState extends State<KycReviewsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<KycCubit>().loadPendingReviews();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final kycCubit = context.read<KycCubit>();

    return DashboardLayout(
      title: AppStrings.kycReviews,
      activeRoute: 'KYC',
      isScrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAdaptivePageHeader(
            title: AppStrings.kycReviews,
            subtitle: AppStrings.kycHeaderDesc,
            primaryAction: AppButton(
              text: AppStrings.refresh,
              icon: Icons.refresh,
              variant: AppButtonVariant.outlined,
              height: 38.h,
              onPressed: () => kycCubit.loadPendingReviews(),
            ),
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: BlocBuilder<KycCubit, KycState>(
              bloc: kycCubit,
              builder: (context, state) {
                if (state.status == KycStatus.loading) {
                  return const TableShimmer(rows: 4, columns: 5);
                }
                if (state.status == KycStatus.failure) {
                  return Center(
                    child: AppText.body(
                      state.errorMessage ?? AppStrings.error,
                      color: AppColors.danger,
                    ),
                  );
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppColors.textSecondary,
            size: 64.r,
          ),
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
      mobileCardBuilder: (context, index) {
        final req = requests[index];
        return Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      req.ownerName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    req.loungeName,
                    style: TextStyle(
                      color: AppColors.neonCyan,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                req.ownerEmail,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              if (req.ownerPhone.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  req.ownerPhone,
                  style: TextStyle(color: AppColors.neonBlue, fontSize: 12.sp),
                ),
              ],
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: AppStrings.viewDocument,
                      icon: Icons.visibility_outlined,
                      variant: AppButtonVariant.outlined,
                      height: 36.h,
                      fontSize: 12.sp,
                      onPressed: () => _showInspection(context, req, cubit),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: AppButton(
                      text: AppStrings.kycInspection,
                      icon: Icons.fact_check_outlined,
                      variant: AppButtonVariant.primary,
                      height: 36.h,
                      fontSize: 12.sp,
                      onPressed: () => _showInspection(context, req, cubit),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      rows: requests
          .map(
            (req) => DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText.body(
                        req.ownerName,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      AppText.body(
                        req.ownerEmail,
                        color: AppColors.textSecondary,
                        fontSize: 11.sp,
                      ),
                      if (req.ownerPhone.isNotEmpty)
                        AppText.body(
                          req.ownerPhone,
                          color: AppColors.neonBlue,
                          fontSize: 11.sp,
                        ),
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
            ),
          )
          .toList(),
    );
  }

  void _showInspection(
    BuildContext context,
    KycRequest request,
    KycCubit cubit,
  ) {
    showDialog(
      context: context,
      builder: (context) => KycInspectionDialog(request: request, cubit: cubit),
    );
  }
}
