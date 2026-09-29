import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/pricing_rule_entity.dart';
import '../repositories/pricing_repository.dart';

class SavePricingRuleParams extends Equatable {
  final PricingRuleEntity rule;

  const SavePricingRuleParams({required this.rule});

  @override
  List<Object?> get props => [rule];
}

class SavePricingRuleUseCase
    implements UseCase<PricingRuleEntity, SavePricingRuleParams> {
  final PricingRepository repository;

  SavePricingRuleUseCase(this.repository);

  @override
  Future<Either<Failure, PricingRuleEntity>> call(
    SavePricingRuleParams params,
  ) {
    return repository.savePricingRule(params.rule);
  }
}
