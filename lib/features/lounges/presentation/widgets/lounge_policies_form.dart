import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge_payment_settings.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_payment_settings_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_payment_settings_state.dart';
import 'lounge_cash_policy_section.dart';
import 'lounge_electronic_payment_section.dart';

class LoungePoliciesForm extends StatefulWidget {
  const LoungePoliciesForm({super.key});

  @override
  State<LoungePoliciesForm> createState() => _LoungePoliciesFormState();
}

class _LoungePoliciesFormState extends State<LoungePoliciesForm> {
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
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

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

    final parsedGracePeriod =
        int.tryParse(_gracePeriodController.text.trim()) ?? 10;
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

    final success =
        await context.read<LoungePaymentSettingsCubit>().saveSettings(settings);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.savePoliciesSuccess),
          backgroundColor: AppColors.success,
        ),
      );
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
        if (state.status == LoungePaymentSettingsStatus.loaded &&
            state.settings != null) {
          if (!_isInitialized) {
            _populateFromSettings(state.settings!);
          }
        } else if (state.status == LoungePaymentSettingsStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == LoungePaymentSettingsStatus.loading;
        final isSaving = state.status == LoungePaymentSettingsStatus.saving;

        if (isLoading && !_isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.neonBlue),
          );
        }

        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                        SizedBox(height: 4.h),
                        Text(
                          AppStrings.loungePoliciesSubtitle,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                    if (canEdit)
                      AppButton(
                        text: AppStrings.saveChanges,
                        isLoading: isSaving,
                        onPressed: isSaving ? null : _handleSave,
                        width: 140.w,
                        height: 40.h,
                      ),
                  ],
                ),
                SizedBox(height: 24.h),
                LoungeCashPolicySection(
                  allowCashPayment: _allowCashPayment,
                  requirePrepaidFirstTime: _requirePrepaidFirstTime,
                  gracePeriodController: _gracePeriodController,
                  canEdit: canEdit,
                  onAllowCashChanged: (val) =>
                      setState(() => _allowCashPayment = val),
                  onRequirePrepaidChanged: (val) =>
                      setState(() => _requirePrepaidFirstTime = val),
                ),
                SizedBox(height: 20.h),
                LoungeElectronicPaymentSection(
                  walletNumberController: _walletNumberController,
                  instapayHandleController: _instapayHandleController,
                  canEdit: canEdit,
                ),
                SizedBox(height: 32.h),
                if (canEdit)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: AppButton(
                      text: AppStrings.saveChanges,
                      isLoading: isSaving,
                      onPressed: isSaving ? null : _handleSave,
                      width: 160.w,
                      height: 44.h,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
