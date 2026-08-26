import '../repositories/shift_repository.dart';

class CloseShiftUseCase {
  final ShiftRepository repository;

  CloseShiftUseCase(this.repository);

  Future<void> call(String shiftId, double actualCashCounted, String? notes) {
    return repository.closeShift(shiftId, actualCashCounted, notes);
  }
}
