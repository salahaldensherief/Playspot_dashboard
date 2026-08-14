import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/repository_helper.dart';
import '../data_source/remote/staff_remote_data_source.dart';
import '../entities/staff_entity.dart';
import '../models/staff_params.dart';

abstract class StaffRepository {
  Future<Either<Failure, List<StaffEntity>>> getLoungeStaff(String loungeId);
  Future<Either<Failure, List<StaffEntity>>> addStaffMember(AddStaffParams params);
  Future<Either<Failure, void>> updateStaffStatus(String staffId, bool isActive);
  Future<Either<Failure, void>> deleteStaff(String staffId);
}

class StaffRepositoryImpl with RepositoryHelper implements StaffRepository {
  final StaffRemoteSource _remoteSource;

  StaffRepositoryImpl(this._remoteSource);

  @override
  Future<Either<Failure, List<StaffEntity>>> getLoungeStaff(String loungeId) async {
    return await callRepository(() => _remoteSource.getLoungeStaff(loungeId));
  }

  @override
  Future<Either<Failure, List<StaffEntity>>> addStaffMember(AddStaffParams params) async {
    return await callRepository(() => _remoteSource.addStaffMember(params));
  }

  @override
  Future<Either<Failure, void>> updateStaffStatus(String staffId, bool isActive) async {
    return await callRepository(() => _remoteSource.updateStaffStatus(staffId, isActive));
  }

  @override
  Future<Either<Failure, void>> deleteStaff(String staffId) async {
    return await callRepository(() => _remoteSource.deleteStaff(staffId));
  }
}
