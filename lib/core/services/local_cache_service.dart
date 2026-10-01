abstract class LocalCacheService {
  Future<void> setJson(String key, dynamic data);
  dynamic getJson(String key);
  Future<void> remove(String key);
  Future<void> clearAll();
}
