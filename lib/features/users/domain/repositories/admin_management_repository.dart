import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';

abstract class AdminManagementRepository {
  Future<Either<Failure, UserEntity>> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeName,
    String? city,
  });
  
  Future<Either<Failure, List<UserEntity>>> getAdmins();
}
