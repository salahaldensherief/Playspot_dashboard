part of 'lounge_setup_view.dart';

extension _LoungeSetupContent on _LoungeSetupViewState {
  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: MultiBlocListener(
        listeners: [
          BlocListener<OnboardingCubit, OnboardingState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) async {
              if (state.status == OnboardingStatus.completed) {
                await Future.delayed(const Duration(milliseconds: 500));
                if (context.mounted) {
                  context.read<LoginCubit>().checkInitialAuth();
                }
              } else if (state.status == OnboardingStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: AppText.body(
                      state.errorMessage ?? AppStrings.actionFailed,
                      color: AppColors.textPrimary,
                    ),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
          ),
          BlocListener<KycCubit, KycState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == KycStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: AppText.body(
                      '${AppStrings.error}: ${state.errorMessage ?? AppStrings.actionFailed}',
                      color: AppColors.textPrimary,
                    ),
                    backgroundColor: AppColors.danger,
                  ),
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
            child: BlocBuilder<OnboardingCubit, OnboardingState>(
              buildWhen: (previous, current) =>
                  previous.currentStep != current.currentStep,
              builder: (context, state) {
                final currentStep = state.currentStep;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 20.h),
                    _buildProgressIndicator(currentStep),
                    SizedBox(height: 32.h),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildStepContent(currentStep),
                      ),
                    ),
                    SizedBox(height: 32.h),
                    _buildActions(currentStep),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
