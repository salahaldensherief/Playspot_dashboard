import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/users/domain/repositories/admin_management_repository.dart';
import 'package:play_spot_dashboard/features/users/data/datasources/admin_management_remote_data_source.dart';

class AdminManagementRepositoryImpl implements AdminManagementRepository {
  final AdminManagementRemoteDataSource remoteDataSource;

  AdminManagementRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, UserEntity>> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeName,
    String? city,
  }) async {
    try {
      final result = await remoteDataSource.createLoungeAdmin(
        email: email,
        password: password,
        name: name,
        loungeName: loungeName,
        city: city,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getAdmins() async {
    try {
      final result = await remoteDataSource.getAdmins();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAdmin(String adminId) async {
    try {
      await remoteDataSource.deleteAdmin(adminId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
