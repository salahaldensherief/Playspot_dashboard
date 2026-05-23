import 'package:dartz/dartz.dart';
import '../sources/auth_remote_source.dart';
import '../../domain/entities/admin_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/error/app_exception.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteSource _remoteSource;

  AuthRepositoryImpl(this._remoteSource);

  @override
  Future<Either<String, AdminEntity>> login(String email, String password) async {
    try {
      final admin = await _remoteSource.login(email, password);
      return Right(admin as AdminEntity);
    } on AppException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> logout() async {
    try {
      await _remoteSource.logout();
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, AdminEntity?>> getCurrentUser() async {
    try {
      final admin = await _remoteSource.getCurrentAdmin();
      return Right(admin as AdminEntity?);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
