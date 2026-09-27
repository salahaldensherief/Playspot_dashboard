import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/support_repository.dart';

class DeleteFaqUseCase {
  final SupportRepository repository;

  DeleteFaqUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteFaq(id);
  }
}
