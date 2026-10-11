import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/pricing_rule_entity.dart';
import '../repositories/pricing_repository.dart';

class CheckPricingRuleConflictsParams extends Equatable {
  final PricingRuleEntity rule;

  const CheckPricingRuleConflictsParams({required this.rule});

  @override
  List<Object?> get props => [rule];
}

class CheckPricingRuleConflictsUseCase
    implements
        UseCase<
          List<PricingRuleEntity>,
          CheckPricingRuleConflictsParams
        > {
  final PricingRepository repository;

  CheckPricingRuleConflictsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PricingRuleEntity>>> call(
    CheckPricingRuleConflictsParams params,
  ) {
    return repository.checkRuleConflicts(params.rule);
  }
}
