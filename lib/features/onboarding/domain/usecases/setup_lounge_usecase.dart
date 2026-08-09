import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/repositories/onboarding_repository.dart';

class SetupLoungeUseCase {
  final OnboardingRepository repository;

  SetupLoungeUseCase(this.repository);

  Future<Either<Failure, Lounge>> call(Lounge lounge) {
    return repository.setupLounge(lounge);
  }
}
