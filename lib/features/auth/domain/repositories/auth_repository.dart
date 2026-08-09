import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/art_core/exceptions/app_exceptions.dart';
import 'package:play_spot_dashboard/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/admin_entity.dart';

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
      return Right(admin);
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
      return Right(admin);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
