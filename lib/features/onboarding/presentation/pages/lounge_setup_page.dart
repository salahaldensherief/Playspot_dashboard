import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/admin_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../widgets/basic_info_step.dart';
import '../widgets/location_step.dart';
import '../widgets/operating_hours_step.dart';

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
    if (_currentStep < 2) {
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
      id: '', // Backend will generate
      name: _nameController.text,
      descriptionEn: _descriptionController.text,
      city: _cityController.text,
      location: _addressController.text,
      opensAt: _opensAtController.text,
      closesAt: _closesAtController.text,
      imageUrl: '', // Should handle image upload later
      categoryId: 'default',
    );

    context.read<OnboardingCubit>().submitLounge(lounge);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: BlocListener<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingSuccess) {
            final authCubit = context.read<LoginCubit>();
            final currentAdmin = authCubit.state.admin;
            if (currentAdmin != null) {
              authCubit.updateAdmin(AdminEntity(
                id: currentAdmin.id,
                userId: currentAdmin.userId,
                role: currentAdmin.role,
                name: currentAdmin.name,
                email: currentAdmin.email,
                loungeId: state.lounge.id,
                avatarUrl: currentAdmin.avatarUrl,
              ));
            }
            context.go(RouterKeys.loungeAdminLiveOps);
          } else if (state is OnboardingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.danger),
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
        Text(
          AppStrings.loungeSetupWelcome,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          AppStrings.loungeSetupSubtitle,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
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
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActions() {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final isLoading = state is OnboardingLoading;
        
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
              text: _currentStep == 2 ? AppStrings.completeSetup : AppStrings.next,
              isLoading: isLoading,
              onPressed: _onNext,
            ),
          ],
        );
      },
    );
  }
}
