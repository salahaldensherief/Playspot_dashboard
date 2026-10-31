import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'offline_key_vault.dart';

class SecureOfflineKeyVault implements OfflineKeyVault {
  final FlutterSecureStorage storage;
  const SecureOfflineKeyVault(this.storage);

  @override
  Future<String?> read(String name) => storage.read(key: name);
  @override
  Future<void> write(String name, String value) =>
      storage.write(key: name, value: value);
}
