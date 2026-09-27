import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/faq_entity.dart';
import '../repositories/support_repository.dart';

class GetFaqsUseCase {
  final SupportRepository repository;

  GetFaqsUseCase(this.repository);

  Future<Either<Failure, List<FaqEntity>>> call() {
    return repository.getFaqs();
  }
}
