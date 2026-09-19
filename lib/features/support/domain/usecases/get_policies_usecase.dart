import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_policy_entity.dart';
import '../repositories/support_repository.dart';

class GetPoliciesUseCase {
  final SupportRepository repository;

  GetPoliciesUseCase(this.repository);

  Future<Either<Failure, List<AppPolicyEntity>>> call() {
    return repository.getPolicies();
  }
}
