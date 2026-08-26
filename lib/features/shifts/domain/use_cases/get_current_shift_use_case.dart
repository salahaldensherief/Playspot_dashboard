import '../entities/shift_entity.dart';
import '../repositories/shift_repository.dart';

class GetCurrentShiftUseCase {
  final ShiftRepository repository;

  GetCurrentShiftUseCase(this.repository);

  Future<ShiftEntity?> call(String loungeId) {
    return repository.getCurrentShift(loungeId);
  }
}
