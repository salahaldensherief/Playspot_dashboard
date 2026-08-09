import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/usecases/setup_lounge_usecase.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final SetupLoungeUseCase setupLoungeUseCase;

  OnboardingCubit(this.setupLoungeUseCase) : super(OnboardingInitial());

  Future<void> submitLounge(Lounge lounge) async {
    emit(OnboardingLoading());
    final result = await setupLoungeUseCase(lounge);
    result.fold(
      (failure) => emit(OnboardingError(failure.message)),
      (lounge) => emit(OnboardingSuccess(lounge)),
    );
  }
}
