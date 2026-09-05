import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/services/local_cache_service.dart';
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
  final LocalCacheService localCacheService;

  LoungeRepositoryImpl(this.remoteDataSource, this.localCacheService);

  @override
  Future<Either<Failure, List<Lounge>>> getLounges({bool forceRefresh = false}) async {
    const cacheKey = 'cache_lounges';
    try {
      if (!forceRefresh) {
        final cached = localCacheService.getJson(cacheKey);
        if (cached is List && cached.isNotEmpty) {
          final cachedLounges = cached
              .map((item) => LoungeModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .map((e) => e as Lounge)
              .toList();
          _refreshLoungesInBackground(cacheKey);
          return Right(cachedLounges);
        }
      }

      final lounges = await remoteDataSource.getLounges();
      final loungeModels = lounges.map((l) => LoungeModel(
        id: l.id,
        name: l.name,
        imageUrl: l.imageUrl,
        rating: l.rating,
        distance: l.distance,
        pricePerHour: l.pricePerHour,
        isOpen: l.isOpen,
        location: l.location,
        city: l.city,
        totalReviews: l.totalReviews,
        availableRooms: l.availableRooms,
        descriptionAr: l.descriptionAr,
        descriptionEn: l.descriptionEn,
        images: l.images,
        opensAt: l.opensAt,
        closesAt: l.closesAt,
        lat: l.lat,
        lng: l.lng,
        categoryIcons: l.categoryIcons,
        categoryId: l.categoryId,
        ownerName: l.ownerName,
        ownerEmail: l.ownerEmail,
        status: l.status,
        hasDiscount: l.hasDiscount,
        discountPercentage: l.discountPercentage,
        discountTitleAr: l.discountTitleAr,
        discountTitleEn: l.discountTitleEn,
        discountExpiresAt: l.discountExpiresAt,
      )).toList();

      await localCacheService.setJson(
        cacheKey,
        loungeModels.map((m) => m.toJson()).toList(),
      );

      return Right(lounges.map((e) => e as Lounge).toList());
    } catch (e) {
      final cached = localCacheService.getJson(cacheKey);
      if (cached is List && cached.isNotEmpty) {
        final cachedLounges = cached
            .map((item) => LoungeModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .map((e) => e as Lounge)
            .toList();
        return Right(cachedLounges);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  void _refreshLoungesInBackground(String cacheKey) async {
    try {
      final lounges = await remoteDataSource.getLounges();
      final loungeModels = lounges.map((l) => LoungeModel(
        id: l.id,
        name: l.name,
        imageUrl: l.imageUrl,
        rating: l.rating,
        distance: l.distance,
        pricePerHour: l.pricePerHour,
        isOpen: l.isOpen,
        location: l.location,
        city: l.city,
        totalReviews: l.totalReviews,
        availableRooms: l.availableRooms,
        descriptionAr: l.descriptionAr,
        descriptionEn: l.descriptionEn,
        images: l.images,
        opensAt: l.opensAt,
        closesAt: l.closesAt,
        lat: l.lat,
        lng: l.lng,
        categoryIcons: l.categoryIcons,
        categoryId: l.categoryId,
        ownerName: l.ownerName,
        ownerEmail: l.ownerEmail,
        status: l.status,
        hasDiscount: l.hasDiscount,
        discountPercentage: l.discountPercentage,
        discountTitleAr: l.discountTitleAr,
        discountTitleEn: l.discountTitleEn,
        discountExpiresAt: l.discountExpiresAt,
      )).toList();

      await localCacheService.setJson(
        cacheKey,
        loungeModels.map((m) => m.toJson()).toList(),
      );
    } catch (_) {}
  }

  @override
  Future<Either<Failure, Lounge?>> getLoungeById(String id, {bool forceRefresh = false}) async {
    final cacheKey = 'cache_lounge_$id';
    try {
      if (!forceRefresh) {
        final cached = localCacheService.getJson(cacheKey);
        if (cached is Map) {
          final model = LoungeModel.fromJson(Map<String, dynamic>.from(cached));
          _refreshLoungeByIdInBackground(id, cacheKey);
          return Right(model);
        }
      }

      final lounge = await remoteDataSource.getLoungeById(id);
      if (lounge != null) {
        final model = LoungeModel(
          id: lounge.id,
          name: lounge.name,
          imageUrl: lounge.imageUrl,
          rating: lounge.rating,
          distance: lounge.distance,
          pricePerHour: lounge.pricePerHour,
          isOpen: lounge.isOpen,
          location: lounge.location,
          city: lounge.city,
          totalReviews: lounge.totalReviews,
          availableRooms: lounge.availableRooms,
          descriptionAr: lounge.descriptionAr,
          descriptionEn: lounge.descriptionEn,
          images: lounge.images,
          opensAt: lounge.opensAt,
          closesAt: lounge.closesAt,
          lat: lounge.lat,
          lng: lounge.lng,
          categoryIcons: lounge.categoryIcons,
          categoryId: lounge.categoryId,
          ownerName: lounge.ownerName,
          ownerEmail: lounge.ownerEmail,
          status: lounge.status,
          hasDiscount: lounge.hasDiscount,
          discountPercentage: lounge.discountPercentage,
          discountTitleAr: lounge.discountTitleAr,
          discountTitleEn: lounge.discountTitleEn,
          discountExpiresAt: lounge.discountExpiresAt,
        );
        await localCacheService.setJson(cacheKey, model.toJson());
      }
      return Right(lounge);
    } catch (e) {
      final cached = localCacheService.getJson(cacheKey);
      if (cached is Map) {
        final model = LoungeModel.fromJson(Map<String, dynamic>.from(cached));
        return Right(model);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  void _refreshLoungeByIdInBackground(String id, String cacheKey) async {
    try {
      final lounge = await remoteDataSource.getLoungeById(id);
      if (lounge != null) {
        final model = LoungeModel(
          id: lounge.id,
          name: lounge.name,
          imageUrl: lounge.imageUrl,
          rating: lounge.rating,
          distance: lounge.distance,
          pricePerHour: lounge.pricePerHour,
          isOpen: lounge.isOpen,
          location: lounge.location,
          city: lounge.city,
          totalReviews: lounge.totalReviews,
          availableRooms: lounge.availableRooms,
          descriptionAr: lounge.descriptionAr,
          descriptionEn: lounge.descriptionEn,
          images: lounge.images,
          opensAt: lounge.opensAt,
          closesAt: lounge.closesAt,
          lat: lounge.lat,
          lng: lounge.lng,
          categoryIcons: lounge.categoryIcons,
          categoryId: lounge.categoryId,
          ownerName: lounge.ownerName,
          ownerEmail: lounge.ownerEmail,
          status: lounge.status,
          hasDiscount: lounge.hasDiscount,
          discountPercentage: lounge.discountPercentage,
          discountTitleAr: lounge.discountTitleAr,
          discountTitleEn: lounge.discountTitleEn,
          discountExpiresAt: lounge.discountExpiresAt,
        );
        await localCacheService.setJson(cacheKey, model.toJson());
      }
    } catch (_) {}
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
      await localCacheService.remove('cache_lounges');
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
      await localCacheService.remove('cache_lounges');
      return Right(result['lounge_id']?.toString() ?? '');
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String? _sanitizeTime(String? timeStr) {
    if (timeStr == null) return null;
    final trimmed = timeStr.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  @override
  Future<Either<Failure, void>> updateLounge(Lounge lounge) async {
    try {
      final openingTime = _sanitizeTime(lounge.opensAt);
      final closingTime = _sanitizeTime(lounge.closesAt);

      final updateMap = <String, dynamic>{
        'name': lounge.name,
        'description_ar': lounge.descriptionAr,
        'description_en': lounge.descriptionEn,
        'city': lounge.city,
        'location': lounge.location,
        'latitude': lounge.lat,
        'longitude': lounge.lng,
        if (openingTime != null) 'opening_time': openingTime,
        if (closingTime != null) 'closing_time': closingTime,
        'image_url': lounge.imageUrl,
        'images': lounge.images,
        'is_open': lounge.isOpen,
        'status': lounge.status,
        'has_discount': lounge.hasDiscount,
        'discount_percentage': lounge.discountPercentage,
        'discount_title_ar': lounge.discountTitleAr,
        'discount_title_en': lounge.discountTitleEn,
        'discount_expires_at': lounge.discountExpiresAt?.toIso8601String(),
      };

      await remoteDataSource.updateLounge(lounge.id, updateMap);
      await localCacheService.remove('cache_lounges');
      await localCacheService.remove('cache_lounge_${lounge.id}');
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
      await localCacheService.remove('cache_lounges');
      await localCacheService.remove('cache_lounge_$loungeId');
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
      await localCacheService.remove('cache_lounges');
      await localCacheService.remove('cache_lounge_$loungeId');
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
  Future<Either<Failure, List<ExtraEntity>>> getExtras(String loungeId, {bool forceRefresh = false}) async {
    final cacheKey = 'cache_extras_$loungeId';
    try {
      if (!forceRefresh) {
        final cached = localCacheService.getJson(cacheKey);
        if (cached is List && cached.isNotEmpty) {
          final extras = cached
              .map((item) => ExtraModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          _refreshExtrasInBackground(loungeId, cacheKey);
          return Right(extras);
        }
      }

      final extras = await remoteDataSource.getExtras(loungeId);
      final models = extras.map((e) => ExtraModel(
        id: e.id,
        loungeId: e.loungeId,
        nameAr: e.nameAr,
        nameEn: e.nameEn,
        name: e.name,
        price: e.price,
        category: e.category,
        iconKey: e.iconKey,
        isOutOfStock: e.isOutOfStock,
        imageUrl: e.imageUrl,
        stockQuantity: e.stockQuantity,
        trackStock: e.trackStock,
        minStockAlert: e.minStockAlert,
      )).toList();

      await localCacheService.setJson(cacheKey, models.map((m) => m.toJson()).toList());
      return Right(extras);
    } catch (e) {
      final cached = localCacheService.getJson(cacheKey);
      if (cached is List && cached.isNotEmpty) {
        final extras = cached
            .map((item) => ExtraModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        return Right(extras);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  void _refreshExtrasInBackground(String loungeId, String cacheKey) async {
    try {
      final extras = await remoteDataSource.getExtras(loungeId);
      final models = extras.map((e) => ExtraModel(
        id: e.id,
        loungeId: e.loungeId,
        nameAr: e.nameAr,
        nameEn: e.nameEn,
        name: e.name,
        price: e.price,
        category: e.category,
        iconKey: e.iconKey,
        isOutOfStock: e.isOutOfStock,
        imageUrl: e.imageUrl,
        stockQuantity: e.stockQuantity,
        trackStock: e.trackStock,
        minStockAlert: e.minStockAlert,
      )).toList();

      await localCacheService.setJson(cacheKey, models.map((m) => m.toJson()).toList());
    } catch (_) {}
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
      await localCacheService.remove('cache_extras_${extra.loungeId}');
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
      await localCacheService.remove('cache_extras_${extra.loungeId}');
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
      await localCacheService.remove('cache_lounges');
      await localCacheService.remove('cache_lounge_$loungeId');
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
      await localCacheService.remove('cache_lounges');
      await localCacheService.remove('cache_lounge_$id');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
