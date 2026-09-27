import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';

class CacheEntry<T> {
  final T data;
  final DateTime cachedAt;

  CacheEntry(this.data, this.cachedAt);

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(cachedAt) > ttl;
  }
}

/// Generic decorator for adding customizable TTL and unified `forceRefresh` handling to any repository fetch method.
class CachedRepositoryDecorator<T> {
  final Map<String, CacheEntry<T>> _cache = {};
  final Duration ttl;

  CachedRepositoryDecorator({this.ttl = const Duration(minutes: 10)});

  Future<Either<Failure, T>> fetch({
    required String key,
    required Future<Either<Failure, T>> Function() fetchFromNetwork,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(key)) {
      final entry = _cache[key]!;
      if (!entry.isExpired(ttl)) {
        return Right(entry.data);
      }
    }

    final result = await fetchFromNetwork();

    result.fold(
      (_) => null,
      (data) {
        _cache[key] = CacheEntry(data, DateTime.now());
      },
    );

    return result;
  }

  void invalidate(String key) {
    _cache.remove(key);
  }

  void clearAll() {
    _cache.clear();
  }
}
