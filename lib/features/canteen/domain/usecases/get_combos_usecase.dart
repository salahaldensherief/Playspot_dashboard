import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/canteen_combo_entity.dart';
import '../repositories/canteen_repository.dart';
import 'get_combos_params.dart';

class GetCombosUseCase
    implements UseCase<List<CanteenComboEntity>, GetCombosParams> {
  final CanteenRepository repository;

  GetCombosUseCase(this.repository);

  @override
  Future<Either<Failure, List<CanteenComboEntity>>> call(
    GetCombosParams params,
  ) {
    return repository.getCombos(
      loungeId: params.loungeId,
      forceRefresh: params.forceRefresh,
    );
  }
}
