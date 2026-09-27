import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/faq_entity.dart';
import '../repositories/support_repository.dart';

class SaveFaqUseCase {
  final SupportRepository repository;

  SaveFaqUseCase(this.repository);

  Future<Either<Failure, void>> call(FaqEntity faq) {
    return repository.saveFaq(faq);
  }
}
