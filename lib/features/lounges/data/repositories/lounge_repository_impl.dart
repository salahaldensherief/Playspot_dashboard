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
import 'package:play_spot_dashboard/features/rooms/data/models/room_model.dart';

class LoungeRepositoryImpl implements LoungeRepository {
  final LoungeRemoteDataSource remoteDataSource;

  LoungeRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Lounge>>> getLounges() async {
    try {
      final lounges = await remoteDataSource.getLounges();
      // تحويل الصريح إلى List<Lounge> لتجنب مشاكل الـ Runtime Type في Dart
      return Right(lounges.map((e) => e as Lounge).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lounge?>> getLoungeById(String id) async {
    try {
      final lounge = await remoteDataSource.getLoungeById(id);
      return Right(lounge);
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
        'latitude': lounge.lat,
        'longitude': lounge.lng,
        'opening_time': lounge.opensAt,
        'closing_time': lounge.closesAt,
        'lat': lounge.lat,
        'lng': lounge.lng,
        'opens_at': lounge.opensAt,
        'closes_at': lounge.closesAt,
        'image_url': lounge.imageUrl,
        'images': lounge.images,
        'is_open': lounge.isOpen,
        'status': lounge.status,
        'has_discount': lounge.hasDiscount,
        'discount_percentage': lounge.discountPercentage,
        'discount_title_ar': lounge.discountTitleAr,
        'discount_title_en': lounge.discountTitleEn,
        'discount_expires_at': lounge.discountExpiresAt?.toIso8601String(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLoungeDiscount({
    required String loungeId,
    required bool hasDiscount,
    required int discountPercentage,
    String? titleAr,
    String? titleEn,
    DateTime? expiresAt,
  }) async {
    try {
      await remoteDataSource.updateLoungeDiscount(
        loungeId,
        hasDiscount: hasDiscount,
        discountPercentage: discountPercentage,
        titleAr: titleAr,
        titleEn: titleEn,
        expiresAt: expiresAt,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLoungeLocation(String loungeId, double lat, double lng) async {
    try {
      await remoteDataSource.updateLounge(loungeId, {
        'latitude': lat,
        'longitude': lng,
        'lat': lat,
        'lng': lng,
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
        nameAr: extra.nameAr,
        nameEn: extra.nameEn,
        name: extra.name,
        price: extra.price,
        category: extra.category,
        isOutOfStock: extra.isOutOfStock,
        iconKey: extra.iconKey,
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateExtra(ExtraEntity extra) async {
    try {
      await remoteDataSource.updateExtra(ExtraModel(
        id: extra.id,
        loungeId: extra.loungeId,
        nameAr: extra.nameAr,
        nameEn: extra.nameEn,
        name: extra.name,
        price: extra.price,
        category: extra.category,
        isOutOfStock: extra.isOutOfStock,
        iconKey: extra.iconKey,
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExtra(String extraId) async {
    try {
      await remoteDataSource.deleteExtra(extraId);
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
  Future<Either<Failure, void>> toggleLoungeOpenStatus(String loungeId, bool isOpen) async {
    try {
      await remoteDataSource.toggleLoungeOpenStatus(loungeId, isOpen);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Activity>>> getActivities(String roomId) async {
    try {
      final data = await remoteDataSource.getActivities(roomId);
      final activities = data.map((json) {
        final type = json['activity_types'];
        return Activity(
          id: json['id']?.toString() ?? '',
          roomId: json['room_id']?.toString() ?? '',
          name: type?['label'] ?? type?['name_en'] ?? type?['name'] ?? '',
          pricePerHour: (json['price_override'] ?? type?['default_price'] ?? 0.0).toDouble(),
          type: type?['category'] ?? '',
        );
      }).toList();
      return Right(activities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Room>>> getRooms(String loungeId) async {
    try {
      final List<RoomModel> roomModels = await remoteDataSource.getRooms(loungeId);
      final rooms = roomModels.map((m) => Room(
        id: m.id,
        loungeId: m.loungeId,
        name: m.nameEn.isEmpty ? m.nameAr : m.nameEn,
        type: m.spaceType ?? '',
      )).toList();
      return Right(rooms);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  @override
  Future<Either<Failure, void>> deleteLounge(String id) async {
    try {
      await remoteDataSource.updateLounge(id, {'status': 'deleted'});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
