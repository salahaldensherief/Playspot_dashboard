import 'package:dartz/dartz.dart';
import '../entities/admin_entity.dart';

abstract class AuthRepository {
  Future<Either<String, AdminEntity>> login(String email, String password);
  Future<Either<String, void>> logout();
  Future<Either<String, AdminEntity?>> getCurrentUser();
}
