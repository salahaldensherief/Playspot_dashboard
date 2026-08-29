import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/shift_entity.dart';
import '../repositories/shift_repository.dart';

class CloseShiftUseCase {
  final ShiftRepository repository;

  CloseShiftUseCase(this.repository);

  Future<Either<Failure, ShiftEntity>> call(String shiftId, double actualCash, String? notes) async {
    return await repository.closeShift(shiftId, actualCash, notes);
  }
}
