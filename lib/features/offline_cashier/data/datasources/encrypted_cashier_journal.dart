import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'offline_key_vault.dart';

class EncryptedCashierJournal {
  static final Map<String, Future<EncryptedCashierJournal>> _opening = {};
  final Box<String> _box;
  final String actorId;
  final String loungeId;
  Future<void> _tail = Future.value();
  Future<void>? _closing;
  EncryptedCashierJournal._(this._box, this.actorId, this.loungeId);

  static Future<EncryptedCashierJournal> open({
    required String ownerId,
    required String loungeId,
    required OfflineKeyVault keys,
  }) async {
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (!uuid.hasMatch(ownerId) || !uuid.hasMatch(loungeId)) {
      throw StateError('offline_cashier.invalid_scope');
    }
    final name =
        'cashier_v1_${ownerId.toLowerCase()}_${loungeId.toLowerCase()}';
    final pending = _opening.putIfAbsent(
      name,
      () => _openBox(name, keys, ownerId.toLowerCase(), loungeId.toLowerCase()),
    );
    try {
      final journal = await pending;
      final closing = journal._closing;
      if (closing != null) {
        await closing;
        return open(ownerId: ownerId, loungeId: loungeId, keys: keys);
      }
      return journal;
    } catch (_) {
      _opening.remove(name);
      rethrow;
    }
  }

  static Future<EncryptedCashierJournal> _openBox(
    String name,
    OfflineKeyVault keys,
    String actorId,
    String loungeId,
  ) async {
    final keyName = 'hive_key_$name';
    final stored = await keys.read(keyName);
    if (stored == null && await Hive.boxExists(name)) {
      // Replacing a lost key would hide unsynchronized financial records.
      throw StateError('offline_cashier.missing_encryption_key');
    }
    final key = stored == null
        ? Hive.generateSecureKey()
        : base64Decode(stored);
    if (key.length != 32) {
      throw StateError('offline_cashier.invalid_encryption_key');
    }
    if (stored == null) await keys.write(keyName, base64Encode(key));
    final box = await Hive.openBox<String>(
      name,
      encryptionCipher: HiveAesCipher(key),
    );
    return EncryptedCashierJournal._(box, actorId, loungeId);
  }

  Map<String, dynamic> _snapshot() {
    final stored = _box.get('aggregate');
    return stored == null
        ? <String, dynamic>{
            'version': 1,
            'bookings': <String, dynamic>{},
            'outbox': <dynamic>[],
          }
        : Map<String, dynamic>.from(jsonDecode(stored) as Map);
  }

  Future<Map<String, dynamic>> read() async {
    await _tail;
    return _snapshot();
  }

  Future<T> mutate<T>(T Function(Map<String, dynamic>) command) {
    if (_closing != null) {
      return Future.error(StateError('offline_cashier.journal_closed'));
    }
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        final snapshot = _snapshot();
        final value = command(snapshot);
        // Projection and outbox share one durable record; neither is committed alone.
        await _box.put('aggregate', jsonEncode(snapshot));
        await _box.flush();
        result.complete(value);
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    await _tail;
    await _box.close();
    _opening.remove(_box.name);
  }
}
