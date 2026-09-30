part of 'lounge_setup_view.dart';

extension _LoungeSetupSections on _LoungeSetupViewState {
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

  Widget _buildProgressIndicator(int currentStep) {
    return Row(
      children: List.generate(_totalSteps, (index) {
        return Expanded(
          child: Container(
            height: 4.h,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              color: index <= currentStep
                  ? AppColors.neonBlue
                  : AppColors.divider,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(int currentStep) {
    final admin = context.read<LoginCubit>().state.user;
    final loungeId = admin?.loungeId ?? 'temp-id';
    final cubit = context.read<OnboardingCubit>();

    switch (currentStep) {
      case 0:
        return VenueTypeStep(
          isChain: _isChain,
          onTypeChanged: (val) {
            _changeVenueType(val);
            _onFieldChanged();
          },
          brandNameController: _brandNameController,
          branchesCountController: _branchesCountController,
          branchNameController: _branchNameController,
        );
      case 1:
        return BasicInfoStep(
          nameController: _nameController,
          descriptionController: _descriptionController,
          contactPhoneController: _contactPhoneController,
          onMainImageSelected: (bytes, name) {
            _mainImageBytes = bytes;
            _mainImageName = name;
          },
          onGallerySelected: (images) {
            _galleryImages = images;
          },
        );
      case 2:
        return LocationStep(
          cityController: _cityController,
          addressController: _addressController,
          onCoordinatesDetected: (lat, lng) {
            cubit.saveDraft(cubit.state.draft.copyWith(lat: lat, lng: lng));
          },
        );
      case 3:
        return OperatingHoursStep(
          opensAtController: _opensAtController,
          closesAtController: _closesAtController,
        );
      case 4:
        return AssetsStep(loungeId: loungeId);
      case 5:
        return MarketplaceStep(loungeId: loungeId);
      case 6:
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
      case 7:
        return OnboardingReviewSummary(
          state: cubit.state,
          ownerName: admin?.name ?? '',
          ownerEmail: admin?.email ?? '',
          hasMainImage: _mainImageBytes?.isNotEmpty == true,
          hasIdentity: _idCardBytes?.isNotEmpty == true,
          hasBusinessDocument: _businessDocBytes?.isNotEmpty == true,
          confirmed: _reviewConfirmed,
          onConfirmed: _confirmReview,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActions(int currentStep) {
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
            final isLoading =
                onboardingState.status == OnboardingStatus.loading ||
                kycState.status == KycStatus.loading;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentStep > 0)
                  AppButton(
                    text: AppStrings.back,
                    variant: AppButtonVariant.outlined,
                    onPressed: _onPrevious,
                  )
                else
                  const SizedBox.shrink(),
                AppButton(
                  text: currentStep == _totalSteps - 1
                      ? 'onboarding_review.submit'.tr()
                      : AppStrings.next,
                  isLoading: isLoading,
                  onPressed: () => _onNext(currentStep),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
