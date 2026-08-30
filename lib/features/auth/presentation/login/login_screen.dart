import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_gradient_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/logo/logo_widget.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';
import 'login_cubit.dart';
import 'login_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.status == LoginStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Login Failed')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Stack(
          children: [
            _buildBackgroundGlows(),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      SizedBox(height: 48.h),
                      _buildLoginCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundGlows() {
    return Stack(
      children: [
        Positioned(
          top: -100.h,
          left: -100.w,
          child: Container(
            width: 300.r,
            height: 300.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonBlue.withOpacity(0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -100.h,
          right: -100.w,
          child: Container(
            width: 300.r,
            height: 300.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonPurple.withOpacity(0.05),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        LogoWidget(
          fontSize: 48.sp,
          width: 50.w,
          height: 50.h,
          color: AppColors.neonBlue,
          animate: false,
        ),
        SizedBox(height: 16.h),
        Text(
          'Gaming Lounge Management',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: Responsive.isMobile(context) ? double.infinity : 450.w,
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                AppStrings.welcomeBack,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Center(
              child: Text(
                AppStrings.signInAccount,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            SizedBox(height: 32.h),
            AppTextField(
              label: AppStrings.email,
              hintText: 'Enter your email',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              validator: AppValidator.validateEmail,
            ),
            SizedBox(height: 24.h),
            AppTextField(
              label: AppStrings.password,
              hintText: 'Enter your password',
              controller: _passwordController,
              isPassword: true,
              prefixIcon: Icons.lock_outline,
              validator: AppValidator.validatePassword,
            ),
            SizedBox(height: 32.h),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return BlocSelector<LoginCubit, LoginState, bool>(
      selector: (state) => state.status == LoginStatus.loading,
      builder: (context, isLoading) {
        return AppGradientButton(
          text: AppStrings.signIn,
          isLoading: isLoading,
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              context.read<LoginCubit>().login(
                _emailController.text.trim(),
                _passwordController.text.trim(),
                context: context,
              );
            }
          },
        );
      },
    );
  }

  Widget _buildDemoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
        ),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 12.sp, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
