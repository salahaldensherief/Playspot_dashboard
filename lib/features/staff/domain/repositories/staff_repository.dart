import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/staff_entity.dart';
import '../../data/models/staff_params.dart';

abstract class StaffRepository {
  Future<Either<Failure, List<StaffEntity>>> getLoungeStaff(String loungeId);
  Future<Either<Failure, void>> addStaffMember(AddStaffParams params);
  Future<Either<Failure, void>> updateStaffMember(String staffId, Map<String, dynamic> data);
  Future<Either<Failure, void>> updateStaffStatus(String staffId, bool isActive);
  Future<Either<Failure, void>> deleteStaff(String staffId);
}
