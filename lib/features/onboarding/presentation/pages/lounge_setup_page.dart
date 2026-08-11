import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/basic_info_step.dart';
import '../widgets/location_step.dart';
import '../widgets/operating_hours_step.dart';
import '../widgets/assets_step.dart';
import '../widgets/marketplace_step.dart';

class LoungeSetupPage extends StatelessWidget {
  const LoungeSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<OnboardingCubit>(),
      child: const LoungeSetupView(),
    );
  }
}

class LoungeSetupView extends StatefulWidget {
  const LoungeSetupView({super.key});

  @override
  State<LoungeSetupView> createState() => _LoungeSetupViewState();
}

class _LoungeSetupViewState extends State<LoungeSetupView> {
  int _currentStep = 0;
  final int _totalSteps = 5;
  
  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _opensAtController = TextEditingController();
  final _closesAtController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _opensAtController.dispose();
    _closesAtController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _onPrevious() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _submit() {
    final lounge = Lounge(
      id: '', 
      name: _nameController.text,
      descriptionEn: _descriptionController.text,
      city: _cityController.text,
      location: _addressController.text,
      opensAt: _opensAtController.text,
      closesAt: _closesAtController.text,
      imageUrl: '', 
      categoryId: 'default',
    );

    context.read<OnboardingCubit>().submitLounge(lounge);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: BlocListener<OnboardingCubit, OnboardingState>(
        listener: (context, state) async {
          if (state.status == OnboardingStatus.success) {
            // Give the UI a moment to breathe before triggering navigation
            // to avoid Flutter Web gesture/rendering collisions.
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              final authCubit = context.read<LoginCubit>();
              authCubit.checkInitialAuth();
            }
          } else if (state.status == OnboardingStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: AppText.body(state.errorMessage ?? 'Error', color: Colors.white), backgroundColor: AppColors.danger),
            );
          }
        },
        child: Center(
          child: Container(
            width: 800.w,
            constraints: BoxConstraints(minHeight: 500.h),
            margin: EdgeInsets.symmetric(vertical: 40.h),
            padding: EdgeInsets.all(40.r),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                SizedBox(height: 20.h),
                _buildProgressIndicator(),
                SizedBox(height: 40.h),
                _buildStepContent(),
                SizedBox(height: 40.h),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.heading(AppStrings.loungeSetupWelcome, fontSize: 32.sp),
        SizedBox(height: 8.h),
        AppText.body(AppStrings.loungeSetupSubtitle, fontSize: 16.sp),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(_totalSteps, (index) {
        return Expanded(
          child: Container(
            height: 4.h,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              color: index <= _currentStep ? AppColors.neonBlue : AppColors.divider,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    final admin = context.read<LoginCubit>().state.user;
    final loungeId = admin?.loungeId ?? 'temp-id';

    switch (_currentStep) {
      case 0:
        return BasicInfoStep(
          nameController: _nameController,
          descriptionController: _descriptionController,
        );
      case 1:
        return LocationStep(
          cityController: _cityController,
          addressController: _addressController,
        );
      case 2:
        return OperatingHoursStep(
          opensAtController: _opensAtController,
          closesAtController: _closesAtController,
        );
      case 3:
        return AssetsStep(loungeId: loungeId);
      case 4:
        return MarketplaceStep(loungeId: loungeId);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActions() {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final isLoading = state.status == OnboardingStatus.loading;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentStep > 0)
              AppButton(
                text: AppStrings.back,
                variant: AppButtonVariant.outlined,
                onPressed: _onPrevious,
              )
            else
              const SizedBox.shrink(),
            AppButton(
              text: _currentStep == _totalSteps - 1 ? AppStrings.completeSetup : AppStrings.next,
              isLoading: isLoading,
              onPressed: _onNext,
            ),
          ],
        );
      },
    );
  }
}
