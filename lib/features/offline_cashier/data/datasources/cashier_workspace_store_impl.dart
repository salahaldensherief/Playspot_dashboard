import 'package:uuid/uuid.dart';
import '../../domain/repositories/cashier_workspace_store.dart';
import '../../domain/repositories/offline_cashier_repository.dart';
import 'cashier_store_factory.dart';
import 'cashier_device_preferences.dart';

class CashierWorkspaceStoreImpl implements CashierWorkspaceStore {
  final CashierStoreFactory factory;
  final CashierDevicePreferences preferences;
  Future<String>? _device;
  CashierWorkspaceStoreImpl(this.factory, this.preferences);
  @override
  Future<String> deviceId() => _device ??= _loadDevice();
  Future<String> _loadDevice() async {
    final saved = preferences.read('device_id');
    if (saved != null && Uuid.isValidUUID(fromString: saved)) return saved;
    final id = const Uuid().v4();
    await preferences.write('device_id', id);
    return id;
  }

  @override
  Future<OfflineCashierRepository> open(String actorId, String loungeId) =>
      factory.open(actorId: actorId, loungeId: loungeId);
}
