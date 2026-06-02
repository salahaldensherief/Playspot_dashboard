import 'package:dartz/dartz.dart';
import '../../../../art_core/exceptions/app_exceptions.dart';
import '../../data/data_source/auth_remote_data_source.dart';
import '../entities/admin_entity.dart';

abstract class AuthRepository {
  Future<Either<String, AdminEntity>> login(String email, String password);
  Future<Either<String, void>> logout();
  Future<Either<String, AdminEntity?>> getCurrentUser();
}
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteSource;

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
