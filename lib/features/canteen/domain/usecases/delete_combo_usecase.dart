import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/canteen_repository.dart';

class DeleteComboUseCase implements UseCase<void, String> {
  final CanteenRepository repository;

  DeleteComboUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deleteCombo(id);
  }
}
