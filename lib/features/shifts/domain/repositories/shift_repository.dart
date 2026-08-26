import '../entities/shift_entity.dart';

abstract class ShiftRepository {
  Future<ShiftEntity?> getCurrentShift(String loungeId);
  Future<void> openShift(String loungeId, double startingCash);
  Future<void> closeShift(String shiftId, double actualCashCounted, String? notes);
  Future<List<ShiftEntity>> getShiftHistory({String? loungeId});
}
