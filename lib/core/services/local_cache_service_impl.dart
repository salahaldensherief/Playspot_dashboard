import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/serialized_task_queue.dart';
import 'local_cache_service.dart';

class LocalCacheServiceImpl implements LocalCacheService {
  final SharedPreferences _prefs;
  final _queue = SerializedTaskQueue();
  LocalCacheServiceImpl(this._prefs);

  String? _ownedKey(String key) {
    final normalized = key.trim();
    return normalized.startsWith('cache_') && normalized.length > 6
        ? normalized
        : null;
  }

  @override
  Future<void> setJson(String key, dynamic data) async {
    final owned = _ownedKey(key);
    if (owned == null) return;
    try {
      final encoded = jsonEncode(data);
      await _queue.run(() async {
        await _prefs.setString(owned, encoded);
      });
    } catch (_) {}
  }

  @override
  dynamic getJson(String key) {
    final owned = _ownedKey(key);
    if (owned == null) return null;
    try {
      final value = _prefs.getString(owned);
      return value == null || value.isEmpty ? null : jsonDecode(value);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    final owned = _ownedKey(key);
    if (owned == null) return;
    try {
      await _queue.run(() => _removeOwned(owned));
    } catch (_) {}
  }

  @override
  Future<void> clearAll() => _queue.run(() async {
    final owned = _prefs.getKeys().where((key) => _ownedKey(key) != null);
    for (final key in owned.toList()) {
      await _removeOwned(key);
    }
  });

  Future<void> _removeOwned(String key) async {
    try {
      if (await _prefs.remove(key)) return;
    } catch (_) {}
    throw StateError('cache.remove_failed');
  }
}
