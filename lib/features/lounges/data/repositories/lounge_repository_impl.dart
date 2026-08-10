import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/activity.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/room.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/extra_entity.dart';
import 'package:play_spot_dashboard/features/lounges/domain/repositories/lounge_repository.dart';
import 'package:play_spot_dashboard/features/lounges/data/datasources/lounge_remote_data_source.dart';
import 'package:play_spot_dashboard/features/lounges/data/models/lounge_model.dart';
import 'package:play_spot_dashboard/features/lounges/data/models/extra_model.dart';

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
  Future<Either<Failure, String>> createLounge(Lounge lounge) async {
    try {
      final id = await remoteDataSource.createLounge(LoungeModel(
        id: lounge.id,
        name: lounge.name,
        location: lounge.location,
        lat: lounge.lat,
        lng: lounge.lng,
        imageUrl: lounge.imageUrl,
        categoryId: lounge.categoryId,
        isOpen: lounge.isOpen,
        opensAt: lounge.opensAt,
        closesAt: lounge.closesAt,
      ));
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeId,
  }) async {
    try {
      await remoteDataSource.createLoungeAdmin(
        email: email,
        password: password,
        name: name,
        loungeId: loungeId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createLoungeWithOwner({
    required String email,
    required String password,
    required String ownerName,
    required String loungeName,
    String? city,
  }) async {
    try {
      final result = await remoteDataSource.createLoungeWithOwner(
        email: email,
        password: password,
        ownerName: ownerName,
        loungeName: loungeName,
        city: city,
      );
      return Right(result['lounge_id']?.toString() ?? '');
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLounge(Lounge lounge) async {
    try {
      await remoteDataSource.updateLounge(lounge.id, {
        'name': lounge.name,
        'description_ar': lounge.descriptionAr,
        'description_en': lounge.descriptionEn,
        'city': lounge.city,
        'location': lounge.location,
        'lat': lounge.lat,
        'lng': lounge.lng,
        'opens_at': lounge.opensAt,
        'closes_at': lounge.closesAt,
        'image_url': lounge.imageUrl,
        'images': lounge.images,
        'is_open': lounge.isOpen,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDashboardStats(String? loungeId) async {
    try {
      final stats = await remoteDataSource.getDashboardStats(loungeId);
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDashboardOverview() async {
    try {
      final overview = await remoteDataSource.getDashboardOverview();
      return Right(overview);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getRevenueOverTime(int daysBack) async {
    try {
      final chart = await remoteDataSource.getRevenueOverTime(daysBack);
      return Right(chart);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getTopLoungesByRevenue(int limitCount) async {
    try {
      final top = await remoteDataSource.getTopLoungesByRevenue(limitCount);
      return Right(top);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ExtraEntity>>> getExtras(String loungeId) async {
    try {
      final extras = await remoteDataSource.getExtras(loungeId);
      return Right(extras);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addExtra(ExtraEntity extra) async {
    try {
      await remoteDataSource.addExtra(ExtraModel(
        id: extra.id,
        loungeId: extra.loungeId,
        name: extra.name,
        price: extra.price,
        category: extra.category,
        isOutOfStock: extra.isOutOfStock,
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleExtraStock(String extraId, bool isOutOfStock) async {
    try {
      await remoteDataSource.toggleExtraStock(extraId, isOutOfStock);
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
  Future<Either<Failure, void>> deleteLounge(String id) => throw UnimplementedError();
}
