import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/canteen_repository.dart';

class DeleteUpsellRuleUseCase implements UseCase<void, String> {
  final CanteenRepository repository;

  DeleteUpsellRuleUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deleteUpsellRule(id);
  }
}
