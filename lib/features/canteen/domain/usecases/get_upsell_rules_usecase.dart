import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/upsell_rule_entity.dart';
import '../repositories/canteen_repository.dart';
import 'get_upsell_rules_params.dart';

class GetUpsellRulesUseCase
    implements UseCase<List<UpsellRuleEntity>, GetUpsellRulesParams> {
  final CanteenRepository repository;

  GetUpsellRulesUseCase(this.repository);

  @override
  Future<Either<Failure, List<UpsellRuleEntity>>> call(
    GetUpsellRulesParams params,
  ) {
    return repository.getUpsellRules(
      loungeId: params.loungeId,
      forceRefresh: params.forceRefresh,
    );
  }
}
