import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/services/local_cache_service.dart';
import 'package:play_spot_dashboard/features/lounges/data/datasources/lounge_remote_data_source.dart';
import 'package:play_spot_dashboard/features/lounges/data/models/extra_model.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/extra_entity.dart';

class LoungeExtrasRepositoryHelper {
  final LoungeRemoteDataSource remoteDataSource;
  final LocalCacheService localCacheService;

  LoungeExtrasRepositoryHelper(this.remoteDataSource, this.localCacheService);

  Future<Either<Failure, List<ExtraEntity>>> getExtras(
    String loungeId, {
    bool forceRefresh = false,
  }) async {
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

  Future<Either<Failure, void>> addExtra(ExtraEntity extra) async {
    try {
      final model = ExtraModel(
        id: extra.id,
        loungeId: extra.loungeId,
        nameAr: extra.nameAr,
        nameEn: extra.nameEn,
        name: extra.name,
        price: extra.price,
        category: extra.category,
        iconKey: extra.iconKey,
        isOutOfStock: extra.isOutOfStock,
        imageUrl: extra.imageUrl,
        stockQuantity: extra.stockQuantity,
        trackStock: extra.trackStock,
        minStockAlert: extra.minStockAlert,
      );
      await remoteDataSource.addExtra(model);
      await localCacheService.remove('cache_extras_${extra.loungeId}');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> updateExtra(ExtraEntity extra) async {
    try {
      final model = ExtraModel(
        id: extra.id,
        loungeId: extra.loungeId,
        nameAr: extra.nameAr,
        nameEn: extra.nameEn,
        name: extra.name,
        price: extra.price,
        category: extra.category,
        iconKey: extra.iconKey,
        isOutOfStock: extra.isOutOfStock,
        imageUrl: extra.imageUrl,
        stockQuantity: extra.stockQuantity,
        trackStock: extra.trackStock,
        minStockAlert: extra.minStockAlert,
      );
      await remoteDataSource.updateExtra(model);
      await localCacheService.remove('cache_extras_${extra.loungeId}');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> deleteExtra(String extraId) async {
    try {
      await remoteDataSource.deleteExtra(extraId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> toggleExtraStock(String extraId, bool isOutOfStock) async {
    try {
      await remoteDataSource.toggleExtraStock(extraId, isOutOfStock);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
