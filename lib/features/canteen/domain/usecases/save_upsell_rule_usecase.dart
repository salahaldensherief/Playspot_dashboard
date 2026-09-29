import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/upsell_rule_entity.dart';
import '../repositories/canteen_repository.dart';

class SaveUpsellRuleUseCase
    implements UseCase<UpsellRuleEntity, UpsellRuleEntity> {
  final CanteenRepository repository;

  SaveUpsellRuleUseCase(this.repository);

  @override
  Future<Either<Failure, UpsellRuleEntity>> call(
    UpsellRuleEntity rule,
  ) {
    return repository.saveUpsellRule(rule);
  }
}
