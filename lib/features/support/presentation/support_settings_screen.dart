import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../art_core/app_strings.dart';
import '../../../art_core/theme/app_colors.dart';
import '../../../art_core/widgets/app_button.dart';
import '../../../art_core/widgets/section_container.dart';
import '../domain/entities/app_settings_entity.dart';
import 'support_cubit.dart';
import 'support_state.dart';

class SupportSettingsScreen extends StatefulWidget {
  const SupportSettingsScreen({super.key});

  @override
  State<SupportSettingsScreen> createState() => _SupportSettingsScreenState();
}

class _SupportSettingsScreenState extends State<SupportSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _whatsappController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _vodafoneController;
  String? _existingId;

  @override
  void initState() {
    super.initState();
    _whatsappController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _vodafoneController = TextEditingController();

    context.read<SupportCubit>().loadAppSettings();
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vodafoneController.dispose();
    super.dispose();
  }

  void _populateFields(AppSettingsEntity settings) {
    _existingId = settings.id;
    if (_whatsappController.text.isEmpty) {
      _whatsappController.text = settings.whatsappPhone;
    }
    if (_phoneController.text.isEmpty) {
      _phoneController.text = settings.supportPhone;
    }
    if (_emailController.text.isEmpty) {
      _emailController.text = settings.supportEmail;
    }
    if (_vodafoneController.text.isEmpty) {
      _vodafoneController.text = settings.vodafoneCashNumber;
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
        if (state.settings != null) {
          _populateFields(state.settings!);
        }

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.contact_support_outlined, color: AppColors.neonBlue, size: 28.r),
                    SizedBox(width: 12.w),
                    Text(
                      AppStrings.supportAndPaymentSettings,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  AppStrings.supportPaymentSettingsSubtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                if (state.status == SupportStatus.loading && state.settings == null)
                  const Center(child: CircularProgressIndicator(color: AppColors.neonBlue))
                else
                  SectionContainer(
                    title: AppStrings.supportContactDetails,
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildInputField(
                              controller: _whatsappController,
                              label: AppStrings.whatsappSupportNumber,
                              hint: AppStrings.hintWhatsappNumber,
                              icon: Icons.chat_bubble_outline,
                            ),
                            SizedBox(height: 16.h),
                            _buildInputField(
                              controller: _phoneController,
                              label: AppStrings.directCallNumber,
                              hint: AppStrings.hintWhatsappNumber,
                              icon: Icons.phone_outlined,
                            ),
                            SizedBox(height: 16.h),
                            _buildInputField(
                              controller: _emailController,
                              label: AppStrings.supportEmailLabel,
                              hint: AppStrings.hintSupportEmail,
                              icon: Icons.email_outlined,
                            ),
                            SizedBox(height: 16.h),
                            _buildInputField(
                              controller: _vodafoneController,
                              label: AppStrings.vodafoneCashOfficialLabel,
                              hint: AppStrings.hintPhoneNumber,
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                            SizedBox(height: 32.h),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: AppButton(
                                text: AppStrings.saveChanges,
                                variant: AppButtonVariant.gradient,
                                icon: Icons.save,
                                isLoading: state.actionStatus == SupportStatus.loading,
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final updatedSettings = AppSettingsEntity(
                                      id: _existingId,
                                      whatsappPhone: _whatsappController.text.trim(),
                                      supportPhone: _phoneController.text.trim(),
                                      supportEmail: _emailController.text.trim(),
                                      vodafoneCashNumber: _vodafoneController.text.trim(),
                                    );
                                    context.read<SupportCubit>().saveAppSettings(updatedSettings);
                                  }
                                },
                              ),
                            ),
                          ],
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
            prefixIcon: Icon(icon, color: AppColors.neonBlue, size: 20.r),
            filled: true,
            fillColor: AppColors.scaffoldBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: AppColors.neonBlue, width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.fieldRequired;
            }
            return null;
          },
        ),
      ],
    );
  }
}
