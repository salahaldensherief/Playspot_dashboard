import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_gradient_button.dart';
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
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          // Background Glows (Simplified)
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
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonBlue.withOpacity(0.2),
                            blurRadius: 20.r,
                            spreadRadius: 2.r,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.sports_esports_outlined,
                        color: AppColors.textPrimary,
                        size: 40.r,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'PlaySpot',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neonBlue,
                        letterSpacing: 1.5,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    Text(
                      'Gaming Lounge Management',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 48.h),
                    
                    // Login Card
                    Container(
                      width: 450.w,
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 24.h),
                            AppTextField(
                              label: AppStrings.password,
                              hintText: 'Enter your password',
                              controller: _passwordController,
                              isPassword: true,
                              prefixIcon: Icons.lock_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 32.h),
                            BlocConsumer<LoginCubit, LoginState>(
                              listener: (context, state) {
                                if (state.status == LoginStatus.authenticated) {
                                  // GoRouter logic in app.dart handles this
                                } else if (state.status == LoginStatus.failure) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(state.errorMessage ?? 'Login Failed')),
                                  );
                                }
                              },
                              builder: (context, state) {
                                return Column(
                                  children: [
                                    AppGradientButton(
                                      text: AppStrings.signIn,
                                      isLoading: state.status == LoginStatus.loading,
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          context.read<LoginCubit>().login(
                                            _emailController.text.trim(),
                                            _passwordController.text.trim(),
                                          );
                                        }
                                      },
                                    ),
                                    SizedBox(height: 16.h),
                                    TextButton(
                                      onPressed: () => context.read<LoginCubit>().loginAsMockLoungeAdmin(),
                                      child: Text(
                                        'Login as Lounge Admin (Dev Mode)',
                                        style: TextStyle(color: AppColors.neonPurple, fontSize: 13.sp),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
