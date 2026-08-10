import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/extra_entity.dart';
import '../repositories/onboarding_repository.dart';

class AddExtraUseCase {
  final OnboardingRepository repository;

  AddExtraUseCase(this.repository);

  Future<Either<Failure, ExtraEntity>> call(ExtraEntity extra) {
    return repository.addExtra(extra);
  }
}
