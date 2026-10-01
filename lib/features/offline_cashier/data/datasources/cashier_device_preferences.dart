import 'package:get_storage/get_storage.dart';

class CashierDevicePreferences {
  final GetStorage storage;
  const CashierDevicePreferences(this.storage);
  static const _allowed = {'locale', 'theme', 'device_id'};

  String? read(String key) {
    if (!_allowed.contains(key)) {
      throw ArgumentError('offline_cashier.invalid_preference');
    }
    return storage.read<String>(key);
  }

  Future<void> write(String key, String value) async {
    if (!_allowed.contains(key)) {
      throw ArgumentError('offline_cashier.invalid_preference');
    }
    await storage.write(key, value);
  }
}
