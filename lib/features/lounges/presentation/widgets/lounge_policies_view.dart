import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge_payment_settings.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_payment_settings_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_payment_settings_state.dart';

/// Lounge Policies & Payment Settings Screen / Widget
/// (شاشة إعدادات سياسات الدفع والحجوزات)
class LoungePoliciesView extends StatelessWidget {
  const LoungePoliciesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoungePaymentSettingsCubit>(),
      child: const _LoungePoliciesForm(),
    );
  }
}

class _LoungePoliciesForm extends StatefulWidget {
  const _LoungePoliciesForm();

  @override
  State<_LoungePoliciesForm> createState() => _LoungePoliciesFormState();
}

class _LoungePoliciesFormState extends State<_LoungePoliciesForm> {
  final _formKey = GlobalKey<FormState>();

  late bool _allowCashPayment;
  late bool _requirePrepaidFirstTime;
  late TextEditingController _gracePeriodController;
  late TextEditingController _walletNumberController;
  late TextEditingController _instapayHandleController;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _allowCashPayment = true;
    _requirePrepaidFirstTime = false;
    _gracePeriodController = TextEditingController(text: '10');
    _walletNumberController = TextEditingController();
    _instapayHandleController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<LoginCubit>().state.user;
      final loungeId = user?.loungeId ?? '';
      if (loungeId.isNotEmpty) {
        context.read<LoungePaymentSettingsCubit>().loadSettings(loungeId);
      }
    });
  }

  void _populateFromSettings(LoungePaymentSettings settings) {
    setState(() {
      _allowCashPayment = settings.allowCashPayment;
      _requirePrepaidFirstTime = settings.requirePrepaidFirstTime;
      _gracePeriodController.text = settings.cashGracePeriodMinutes.toString();
      _walletNumberController.text = settings.walletNumber ?? '';
      _instapayHandleController.text = settings.instapayHandle ?? '';
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _gracePeriodController.dispose();
    _walletNumberController.dispose();
    _instapayHandleController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;

    final user = context.read<LoginCubit>().state.user;
    final canEdit = user?.isLoungeOwner == true ||
        user?.isSuperAdmin == true ||
        user?.isManager == true;

    if (!canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.permissionDeniedEditPolicies),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final loungeId = user?.loungeId ?? '';
    if (loungeId.isEmpty) return;

    final parsedGracePeriod = int.tryParse(_gracePeriodController.text.trim()) ?? 10;
    final wallet = _walletNumberController.text.trim();
    final instapay = _instapayHandleController.text.trim();

    final settings = LoungePaymentSettings(
      loungeId: loungeId,
      allowCashPayment: _allowCashPayment,
      requirePrepaidFirstTime: _requirePrepaidFirstTime,
      cashGracePeriodMinutes: parsedGracePeriod,
      walletNumber: wallet.isNotEmpty ? wallet : null,
      instapayHandle: instapay.isNotEmpty ? instapay : null,
    );

    final success = await context.read<LoungePaymentSettingsCubit>().saveSettings(settings);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.savePoliciesSuccess),
          backgroundColor: AppColors.success,
        ),
      );

      // Refresh LoginCubit state to stay synchronized
      context.read<LoginCubit>().refreshUserLounge(loungeId, forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<LoginCubit>().state.user;
    final canEdit = user?.isLoungeOwner == true ||
        user?.isSuperAdmin == true ||
        user?.isManager == true;

    return BlocConsumer<LoungePaymentSettingsCubit, LoungePaymentSettingsState>(
      listener: (context, state) {
        if (state.status == LoungePaymentSettingsStatus.loaded && state.settings != null) {
          if (!_isInitialized) {
            _populateFromSettings(state.settings!);
          }
        } else if (state.status == LoungePaymentSettingsStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == LoungePaymentSettingsStatus.loading && !_isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.neonBlue),
          );
        }

        final isSaving = state.status == LoungePaymentSettingsStatus.saving;

        return SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.neonBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: const Icon(Icons.security_rounded, color: AppColors.neonBlue, size: 24),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.loungePoliciesTitle,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          AppStrings.loungePoliciesSubtitle,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // 1. Cash & Prepaid Toggles Card
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.borderDefault),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined, color: AppColors.warning),
                          SizedBox(width: 8.w),
                          Text(
                            AppStrings.cashPoliciesTitle,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Toggle 1: allow_cash_payment
                      SwitchListTile(
                        value: _allowCashPayment,
                        onChanged: canEdit ? (val) => setState(() => _allowCashPayment = val) : null,
                        activeThumbColor: AppColors.neonBlue,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          AppStrings.allowCashPaymentLabel,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          AppStrings.allowCashPaymentHint,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5.sp,
                          ),
                        ),
                      ),
                      const Divider(color: AppColors.borderDefault),

                      // Toggle 2: require_prepaid_first_time
                      SwitchListTile(
                        value: _requirePrepaidFirstTime,
                        onChanged: canEdit ? (val) => setState(() => _requirePrepaidFirstTime = val) : null,
                        activeThumbColor: AppColors.warning,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          AppStrings.requirePrepaidFirstTimeLabel,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          AppStrings.requirePrepaidFirstTimeHint,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // 2. Cash Grace Period Field (0 - 1440 min)
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.borderDefault),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: AppColors.neonPurple),
                          SizedBox(width: 8.w),
                          Text(
                            AppStrings.cashGracePeriodLabel,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        AppStrings.cashGracePeriodHint,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5.sp),
                      ),
                      SizedBox(height: 16.h),

                      AppTextField(
                        controller: _gracePeriodController,
                        label: AppStrings.gracePeriodFieldLabel,
                        hintText: '10',
                        keyboardType: TextInputType.number,
                        enabled: canEdit,
                        prefixIcon: Icons.access_time_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.gracePeriodRequiredError;
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null) {
                            return AppStrings.invalidNumberError;
                          }
                          if (parsed < 0 || parsed > 1440) {
                            return AppStrings.gracePeriodRangeError;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // 3. Wallet Number & InstaPay Handle
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.borderDefault),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, color: AppColors.neonGreen),
                          SizedBox(width: 8.w),
                          Text(
                            AppStrings.paymentMethodsTitle,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        AppStrings.paymentMethodsHint,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5.sp),
                      ),
                      SizedBox(height: 16.h),

                      AppTextField(
                        controller: _walletNumberController,
                        label: AppStrings.walletNumberFieldLabel,
                        hintText: '01xxxxxxxxx',
                        enabled: canEdit,
                        prefixIcon: Icons.phone_android_rounded,
                      ),
                      SizedBox(height: 16.h),

                      AppTextField(
                        controller: _instapayHandleController,
                        label: AppStrings.instapayHandleFieldLabel,
                        hintText: 'username@instapay',
                        enabled: canEdit,
                        prefixIcon: Icons.alternate_email_rounded,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),

                // Save Action
                if (canEdit)
                  AppButton(
                    text: AppStrings.saveChanges,
                    isLoading: isSaving,
                    icon: Icons.save_rounded,
                    onPressed: _handleSave,
                    width: 220.w,
                    height: 44.h,
                  ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        );
      },
    );
  }
}
