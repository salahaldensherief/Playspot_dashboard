import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/repositories/onboarding_repository.dart';

class BatchCompleteOnboardingUseCase {
  final OnboardingRepository repository;

  BatchCompleteOnboardingUseCase(this.repository);

  Future<Either<Failure, Lounge>> call({
    required String loungeId,
    required Map<String, dynamic> loungeData,
    required List<Map<String, dynamic>> rooms,
    required List<Map<String, dynamic>> extras,
  }) {
    return repository.batchCompleteOnboarding(
      loungeId: loungeId,
      loungeData: loungeData,
      rooms: rooms,
      extras: extras,
    );
  }
}
