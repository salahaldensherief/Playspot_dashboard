import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../art_core/app_strings.dart';
import '../../../art_core/theme/app_colors.dart';
import '../../../art_core/widgets/app_adaptive_page_header.dart';
import '../../../art_core/widgets/app_button.dart';
import '../../../art_core/widgets/section_container.dart';
import '../domain/entities/app_policy_entity.dart';
import 'support_cubit.dart';
import 'support_state.dart';

class PolicyManagementScreen extends StatefulWidget {
  const PolicyManagementScreen({super.key});

  @override
  State<PolicyManagementScreen> createState() => _PolicyManagementScreenState();
}

class _PolicyManagementScreenState extends State<PolicyManagementScreen> {
  String _selectedPolicyType = 'terms_of_service';

  final _titleArController = TextEditingController();
  final _titleEnController = TextEditingController();
  final _contentArController = TextEditingController();
  final _contentEnController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().loadPolicies();
  }

  @override
  void dispose() {
    _titleArController.dispose();
    _titleEnController.dispose();
    _contentArController.dispose();
    _contentEnController.dispose();
    super.dispose();
  }

  void _loadPolicyToForm(List<AppPolicyEntity> policies) {
    final policy = policies.firstWhere(
      (p) => p.policyType == _selectedPolicyType,
      orElse: () => AppPolicyEntity(
        id: '',
        policyType: _selectedPolicyType,
        titleAr: _getDefaultTitleAr(_selectedPolicyType),
        titleEn: _getDefaultTitleEn(_selectedPolicyType),
        contentAr: '',
        contentEn: '',
      ),
    );

    _titleArController.text = policy.titleAr;
    _titleEnController.text = policy.titleEn;
    _contentArController.text = policy.contentAr;
    _contentEnController.text = policy.contentEn;
  }

  String _getDefaultTitleAr(String type) {
    switch (type) {
      case 'terms_of_service':
        return AppStrings.termsOfService;
      case 'privacy_policy':
        return AppStrings.privacyPolicy;
      case 'refund_policy':
        return AppStrings.refundPolicy;
      default:
        return AppStrings.policy;
    }
  }

  String _getDefaultTitleEn(String type) {
    switch (type) {
      case 'terms_of_service':
        return AppStrings.termsOfService;
      case 'privacy_policy':
        return AppStrings.privacyPolicy;
      case 'refund_policy':
        return AppStrings.refundPolicy;
      default:
        return AppStrings.policy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SupportCubit, SupportState>(
      listenWhen: (prev, curr) =>
          prev.actionStatus != curr.actionStatus ||
          prev.successMessage != curr.successMessage ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.actionStatus == SupportStatus.success && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state.actionStatus == SupportStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.policies.isNotEmpty) {
          _loadPolicyToForm(state.policies);
        }

        final currentPolicy = state.policies.firstWhere(
          (p) => p.policyType == _selectedPolicyType,
          orElse: () => AppPolicyEntity(
            id: '',
            policyType: _selectedPolicyType,
            titleAr: _getDefaultTitleAr(_selectedPolicyType),
            titleEn: _getDefaultTitleEn(_selectedPolicyType),
            contentAr: '',
            contentEn: '',
          ),
        );

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAdaptivePageHeader(
                  title: AppStrings.policiesManagement,
                  subtitle: AppStrings.policiesManagementSubtitle,
                  primaryAction: AppButton(
                    text: AppStrings.savePolicy,
                    icon: Icons.save_outlined,
                    isLoading: state.actionStatus == SupportStatus.loading,
                    onPressed: () {
                      final updated = AppPolicyEntity(
                        id: currentPolicy.id,
                        policyType: _selectedPolicyType,
                        titleAr: _titleArController.text.trim(),
                        titleEn: _titleEnController.text.trim(),
                        contentAr: _contentArController.text.trim(),
                        contentEn: _contentEnController.text.trim(),
                      );
                      context.read<SupportCubit>().savePolicy(updated);
                    },
                  ),
                ),
                SizedBox(height: 24.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabButton('terms_of_service', AppStrings.termsOfService, Icons.assignment_outlined),
                      SizedBox(width: 12.w),
                      _buildTabButton('privacy_policy', AppStrings.privacyPolicy, Icons.privacy_tip_outlined),
                      SizedBox(width: 12.w),
                      _buildTabButton('refund_policy', AppStrings.refundPolicy, Icons.event_busy_outlined),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                if (state.status == SupportStatus.loading && state.policies.isEmpty)
                  const Center(child: CircularProgressIndicator(color: AppColors.neonBlue))
                else
                  SectionContainer(
                    title: _getDefaultTitleAr(_selectedPolicyType),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildPolicyColumn(
                              isArabic: true,
                              titleController: _titleArController,
                              contentController: _contentArController,
                            ),
                          ),
                          SizedBox(width: 24.w),
                          Expanded(
                            child: _buildPolicyColumn(
                              isArabic: false,
                              titleController: _titleEnController,
                              contentController: _contentEnController,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 32.h),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: AppButton(
                          text: AppStrings.savePolicy,
                          variant: AppButtonVariant.gradient,
                          icon: Icons.publish_outlined,
                          isLoading: state.actionStatus == SupportStatus.loading,
                          onPressed: () {
                            final policyToSave = AppPolicyEntity(
                              id: currentPolicy.id,
                              policyType: _selectedPolicyType,
                              titleAr: _titleArController.text.trim(),
                              titleEn: _titleEnController.text.trim(),
                              contentAr: _contentArController.text.trim(),
                              contentEn: _contentEnController.text.trim(),
                              isPublished: true,
                            );
                            context.read<SupportCubit>().savePolicy(policyToSave);
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String type, String label, IconData icon) {
    final isSelected = _selectedPolicyType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPolicyType = type;
        });
      },
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonBlue.withValues(alpha: 0.15) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? AppColors.neonBlue : AppColors.borderDefault,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
              size: 18.r,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.neonBlue : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyColumn({
    required bool isArabic,
    required TextEditingController titleController,
    required TextEditingController contentController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isArabic ? Icons.language : Icons.translate,
              color: AppColors.neonPurple,
              size: 20.r,
            ),
            SizedBox(width: 8.w),
            Text(
              isArabic ? AppStrings.arabicLanguage : AppStrings.englishLanguage,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          isArabic ? AppStrings.policyTitleAr : AppStrings.policyTitleEn,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: titleController,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.scaffoldBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          isArabic ? AppStrings.policyContentAr : AppStrings.policyContentEn,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: contentController,
          maxLines: 12,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: isArabic ? AppStrings.policyContentArHint : AppStrings.policyContentEnHint,
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
            filled: true,
            fillColor: AppColors.scaffoldBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        ),
      ],
    );
  }
}
