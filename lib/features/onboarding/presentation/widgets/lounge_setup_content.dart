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
              if (state.status == OnboardingStatus.restored) {
                _restoreFields(state);
              }
              if (state.status == OnboardingStatus.completed) {
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
        child: SafeArea(
          child: Center(
            child: Container(
              width: math.min(800, MediaQuery.sizeOf(context).width - 32),
              height: math.max(
                0,
                MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).bottom -
                    MediaQuery.paddingOf(context).top -
                    MediaQuery.paddingOf(context).bottom -
                    32,
              ),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: BlocBuilder<OnboardingCubit, OnboardingState>(
                buildWhen: (previous, current) =>
                    previous.currentStep != current.currentStep ||
                    previous.status != current.status,
                builder: (context, state) {
                  final currentStep = state.currentStep;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: AbsorbPointer(
                            absorbing:
                                _isSubmitting ||
                                state.status == OnboardingStatus.loading,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                if (state.reviewNotes?.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: AppText.body(
                                      state.reviewNotes ?? '',
                                      fontSize: 16,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                _buildProgressIndicator(currentStep),
                                const SizedBox(height: 32),
                                _buildStepContent(currentStep),
                              ],
                            ),
                          ),
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
      ),
    );
  }
}
