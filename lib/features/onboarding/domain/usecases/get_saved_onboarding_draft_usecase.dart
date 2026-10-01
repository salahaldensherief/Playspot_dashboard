import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/saved_onboarding_draft.dart';
import '../repositories/onboarding_repository.dart';

class GetSavedOnboardingDraftUseCase {
  final OnboardingRepository repository;
  const GetSavedOnboardingDraftUseCase(this.repository);
  Future<Either<Failure, SavedOnboardingDraft>> call(String loungeId) =>
      repository.getSavedDraft(loungeId);
}
