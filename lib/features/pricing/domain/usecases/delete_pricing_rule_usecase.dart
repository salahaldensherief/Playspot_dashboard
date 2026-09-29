import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/pricing_repository.dart';

class DeletePricingRuleParams extends Equatable {
  final String id;

  const DeletePricingRuleParams({required this.id});

  @override
  List<Object?> get props => [id];
}

class DeletePricingRuleUseCase
    implements UseCase<void, DeletePricingRuleParams> {
  final PricingRepository repository;

  DeletePricingRuleUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeletePricingRuleParams params) {
    return repository.deletePricingRule(params.id);
  }
}
