import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_multi_image_picker.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/cubit/kyc_cubit.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/cubit/kyc_state.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/widgets/kyc_step.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import 'basic_info_step.dart';
import 'location_step.dart';
import 'operating_hours_step.dart';
import 'assets_step.dart';
import 'marketplace_step.dart';

class LoungeSetupView extends StatefulWidget {
  const LoungeSetupView({super.key});

  @override
  State<LoungeSetupView> createState() => _LoungeSetupViewState();
}

class _LoungeSetupViewState extends State<LoungeSetupView> {
  int _currentStep = 0;
  final int _totalSteps = 6;
  
  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _opensAtController = TextEditingController();
  final _closesAtController = TextEditingController();

  Uint8List? _mainImageBytes;
  String? _mainImageName;
  List<SelectedImage> _galleryImages = [];

  // KYC Data
  Uint8List? _idCardBytes;
  String? _idCardName;
  Uint8List? _businessDocBytes;
  String? _businessDocName;

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

  Future<void> _submit() async {
    final user = context.read<LoginCubit>().state.user;
    final kycCubit = context.read<KycCubit>();
    final onboardingCubit = context.read<OnboardingCubit>();
    
    final loungeId = user?.loungeId ?? '';
    final userId = user?.id ?? '';

    if (_idCardBytes != null) {
      await kycCubit.submitKyc(
        userId: userId,
        idCardBytes: _idCardBytes!,
        idCardName: _idCardName!,
        businessDocBytes: _businessDocBytes,
        businessDocName: _businessDocName,
      );
    }

    final lounge = Lounge(
      id: loungeId, 
      name: _nameController.text,
      descriptionEn: _descriptionController.text,
      city: _cityController.text,
      location: _addressController.text,
      opensAt: _opensAtController.text,
      closesAt: _closesAtController.text,
      imageUrl: '', 
      categoryId: null,
    );

    onboardingCubit.submitLounge(
      lounge: lounge,
      mainImageBytes: _mainImageBytes,
      mainImageName: _mainImageName,
      galleryImages: _galleryImages,
      loungeId: loungeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: MultiBlocListener(
        listeners: [
          BlocListener<OnboardingCubit, OnboardingState>(
            listenWhen: (previous, current) => previous.status != current.status,
            listener: (context, state) async {
              if (state.status == OnboardingStatus.success) {
                await Future.delayed(const Duration(milliseconds: 500));
                if (mounted) {
                  context.read<LoginCubit>().checkInitialAuth();
                }
              } else if (state.status == OnboardingStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: AppText.body(state.errorMessage ?? AppStrings.actionFailed, color: Colors.white), backgroundColor: AppColors.danger),
                );
              }
            },
          ),
          BlocListener<KycCubit, KycState>(
            listenWhen: (previous, current) => previous.status != current.status,
            listener: (context, state) {
              if (state.status == KycStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: AppText.body('KYC Error: ${state.errorMessage}', color: Colors.white), backgroundColor: AppColors.danger),
                );
              }
            },
          ),
        ],
        child: Center(
          child: Container(
            width: 800.w,
            height: 850.h,
            margin: EdgeInsets.symmetric(vertical: 24.h),
            padding: EdgeInsets.all(40.r),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 20.h),
                _buildProgressIndicator(),
                SizedBox(height: 32.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildStepContent(),
                  ),
                ),
                SizedBox(height: 32.h),
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
          onMainImageSelected: (bytes, name) {
            _mainImageBytes = bytes;
            _mainImageName = name;
          },
          onGallerySelected: (images) {
            _galleryImages = images;
          },
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
      case 5:
        return KycStep(
          onIdCardSelected: (bytes, name) {
            _idCardBytes = bytes;
            _idCardName = name;
          },
          onBusinessDocSelected: (bytes, name) {
            _businessDocBytes = bytes;
            _businessDocName = name;
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActions() {
    final onboardingCubit = context.read<OnboardingCubit>();
    final kycCubit = context.read<KycCubit>();

    return BlocBuilder<OnboardingCubit, OnboardingState>(
      bloc: onboardingCubit,
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, onboardingState) {
        return BlocBuilder<KycCubit, KycState>(
          bloc: kycCubit,
          buildWhen: (previous, current) => previous.status != current.status,
          builder: (context, kycState) {
            final isLoading = onboardingState.status == OnboardingStatus.loading || 
                              kycState.status == KycStatus.loading;
            
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
      },
    );
  }
}
