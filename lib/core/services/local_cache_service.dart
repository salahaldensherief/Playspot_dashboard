import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalCacheService {
  Future<void> setJson(String key, dynamic data);
  dynamic getJson(String key);
  Future<void> remove(String key);
  Future<void> clearAll();
}

class LocalCacheServiceImpl implements LocalCacheService {
  final SharedPreferences _prefs;

  LocalCacheServiceImpl(this._prefs);

  @override
  Future<void> setJson(String key, dynamic data) async {
    try {
      final jsonString = jsonEncode(data);
      await _prefs.setString(key, jsonString);
    } catch (_) {
      // Ignore cache write errors gracefully
    }
  }

  @override
  dynamic getJson(String key) {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) return null;
      return jsonDecode(jsonString);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
    } catch (_) {}
  }

  @override
  Future<void> clearAll() async {
    try {
      await _prefs.clear();
    } catch (_) {}
  }
}
