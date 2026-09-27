import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';

class KycPendingPage extends StatelessWidget {
  const KycPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Container(
            width: 600.w,
            padding: EdgeInsets.all(40.r),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: AppColors.borderDefault),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.05),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: BlocBuilder<LoginCubit, LoginState>(
              builder: (context, loginState) {
                final lounge = loginState.userLounge;
                final user = loginState.user;
                final isLoading = loginState.status == LoginStatus.checking || loginState.status == LoginStatus.loading;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Header
                    Container(
                      width: 80.r,
                      height: 80.r,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Icon(
                        Icons.hourglass_top_rounded,
                        color: AppColors.warning,
                        size: 40.r,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Title & Status Badge
                    AppText.heading(
                      'بيانات الصالة قيد المراجعة',
                      fontSize: 24.sp,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    StatusBadge.warning('قيد المراجعة والتدقيق'),
                    SizedBox(height: 24.h),

                    // Description Notice
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.mutedBackground,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.neonBlue, size: 20.r),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: AppText.subHeading(
                                  lounge?.name.isNotEmpty == true ? lounge!.name : (user?.name ?? 'PlaySpot Lounge'),
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          AppText.body(
                            'تم استلام مستندات الهوية وتفاصيل الصالة بنجاح. طلبك حالياً قيد المراجعة الفنية والأمنية من قِبل إدارة منصة PlaySpot. وسيتم تفعيل الصالة وإتاحتها للجمهور وفور اعتماد البيانات.',
                            fontSize: 13.sp,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Verification Checklist
                    _buildChecklistItem(
                      title: 'مستندات الهوية والسجل التجاري',
                      subtitle: 'تم الرفع • بانتظار اعتماد المراجع الأمني',
                      isPending: true,
                    ),
                    SizedBox(height: 12.h),
                    _buildChecklistItem(
                      title: 'ظهور الصالة للجمهور والتطبيق',
                      subtitle: 'معطل مؤقتاً • يتم التفعيل فور الاعتماد',
                      isPending: true,
                    ),
                    SizedBox(height: 12.h),
                    _buildChecklistItem(
                      title: 'لوحة التحكم والعمليات المباشرة',
                      subtitle: 'مغلقة مؤقتاً حتى قبول الطلب',
                      isPending: true,
                    ),

                    SizedBox(height: 32.h),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'إعادة فحص الحالة',
                            variant: AppButtonVariant.primary,
                            isLoading: isLoading,
                            icon: Icons.refresh_rounded,
                            onPressed: () {
                              context.read<LoginCubit>().checkInitialAuth();
                            },
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: AppButton(
                            text: AppStrings.logout,
                            variant: AppButtonVariant.outlined,
                            icon: Icons.logout,
                            onPressed: () {
                              context.read<LoginCubit>().logout();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required String subtitle,
    required bool isPending,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Icon(
            isPending ? Icons.pending_actions_rounded : Icons.check_circle_outline,
            color: isPending ? AppColors.warning : AppColors.success,
            size: 20.r,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.body(title, fontSize: 13.sp, fontWeight: FontWeight.w600),
                AppText.body(subtitle, fontSize: 11.sp, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
