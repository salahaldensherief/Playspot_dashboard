import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/upsell_conversion_entity.dart';
import '../repositories/canteen_repository.dart';

class GetUpsellConversionsUseCase
    implements UseCase<List<UpsellConversionEntity>, String> {
  final CanteenRepository repository;

  GetUpsellConversionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<UpsellConversionEntity>>> call(String loungeId) {
    return repository.getUpsellConversions(loungeId: loungeId);
  }
}
