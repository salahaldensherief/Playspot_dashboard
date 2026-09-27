import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_policy_entity.dart';
import '../repositories/support_repository.dart';

class UpdatePolicyUseCase {
  final SupportRepository repository;

  UpdatePolicyUseCase(this.repository);

  Future<Either<Failure, void>> call(AppPolicyEntity policy) {
    return repository.updatePolicy(policy);
  }
}
