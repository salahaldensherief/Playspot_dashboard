import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Keeps the same operation ID after a lost response or a browser restart.
class CashCheckoutOperationStore {
  const CashCheckoutOperationStore();

  static final Map<String, Future<String>> _inFlight = {};

  Future<String> getOrCreate(String requestKey) {
    final key =
        'cash_checkout_operation_v1:${sha256.convert(utf8.encode(requestKey))}';
    return _inFlight.putIfAbsent(key, () async {
      try {
        return await _readOrCreate(key);
      } finally {
        _inFlight.remove(key);
      }
    });
  }

  Future<String> _readOrCreate(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(key);
    if (existing != null && existing.isNotEmpty) return existing;
    final operationId = const Uuid().v4();
    if (!await preferences.setString(key, operationId)) {
      throw StateError('CASH_CHECKOUT_OPERATION_NOT_PERSISTED');
    }
    return operationId;
  }
}
