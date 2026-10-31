import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/pricing_rule_entity.dart';
import '../repositories/pricing_repository.dart';

class GetPricingRulesParams extends Equatable {
  final String loungeId;

  const GetPricingRulesParams({required this.loungeId});

  @override
  List<Object?> get props => [loungeId];
}

class GetPricingRulesUseCase
    implements UseCase<List<PricingRuleEntity>, GetPricingRulesParams> {
  final PricingRepository repository;

  GetPricingRulesUseCase(this.repository);

  @override
  Future<Either<Failure, List<PricingRuleEntity>>> call(
    GetPricingRulesParams params,
  ) {
    return repository.getPricingRules(loungeId: params.loungeId);
  }
}
