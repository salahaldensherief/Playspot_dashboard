import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/admin_entity.dart';

abstract class AdminManagementRepository {
  Future<Either<Failure, AdminEntity>> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
  });
}
