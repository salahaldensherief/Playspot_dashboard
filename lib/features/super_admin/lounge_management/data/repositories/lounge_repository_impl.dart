import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/super_admin/lounge_management/domain/entities/activity.dart';
import 'package:play_spot_dashboard/features/super_admin/lounge_management/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/super_admin/lounge_management/domain/entities/room.dart';
import 'package:play_spot_dashboard/features/super_admin/lounge_management/domain/repositories/lounge_repository.dart';
import 'package:play_spot_dashboard/features/super_admin/lounge_management/data/datasources/lounge_remote_data_source.dart';
import 'package:play_spot_dashboard/features/super_admin/lounge_management/data/models/lounge_model.dart';

class LoungeRepositoryImpl implements LoungeRepository {
  final LoungeRemoteDataSource remoteDataSource;

  LoungeRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Lounge>>> getLounges() async {
    try {
      final lounges = await remoteDataSource.getLounges();
      return Right(lounges);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createLounge(Lounge lounge) async {
    try {
      await remoteDataSource.createLounge(LoungeModel(
        id: lounge.id,
        name: lounge.name,
        location: lounge.location,
        lat: lounge.lat,
        lng: lounge.lng,
        imageUrl: lounge.imageUrl,
        categoryId: lounge.categoryId,
        isOpen: lounge.isOpen,
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Activity>>> getActivities(String roomId) => throw UnimplementedError();
  @override
  Future<Either<Failure, List<Room>>> getRooms(String loungeId) => throw UnimplementedError();
  @override
  Future<Either<Failure, void>> updateLounge(Lounge lounge) => throw UnimplementedError();
  @override
  Future<Either<Failure, void>> deleteLounge(String id) => throw UnimplementedError();
}
