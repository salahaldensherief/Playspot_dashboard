import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/canteen_combo_entity.dart';
import '../repositories/canteen_repository.dart';

class SaveComboUseCase
    implements UseCase<CanteenComboEntity, CanteenComboEntity> {
  final CanteenRepository repository;

  SaveComboUseCase(this.repository);

  @override
  Future<Either<Failure, CanteenComboEntity>> call(
    CanteenComboEntity combo,
  ) {
    return repository.saveCombo(combo);
  }
}
