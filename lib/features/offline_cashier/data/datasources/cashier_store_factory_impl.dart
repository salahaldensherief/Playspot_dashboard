import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/offline_cashier_repository.dart';
import '../repositories/offline_cashier_repository_impl.dart';
import 'cashier_store_factory.dart';
import 'offline_key_vault.dart';
import 'encrypted_cashier_journal.dart';
import 'local_cashier_commands.dart';
import 'cashier_outbox_synchronizer.dart';
import 'supabase_cashier_sync_transport.dart';

class CashierStoreFactoryImpl implements CashierStoreFactory {
  final OfflineKeyVault keys;
  final SupabaseClient client;
  final Map<String, Future<OfflineCashierRepository>> _repositories = {};
  CashierStoreFactoryImpl({required this.keys, required this.client});

  @override
  Future<OfflineCashierRepository> open({
    required String actorId,
    required String loungeId,
  }) async {
    if (client.auth.currentUser?.id != actorId) {
      throw StateError('offline_cashier.permission_denied');
    }
    final key = '$actorId/$loungeId';
    final opening = _repositories.putIfAbsent(
      key,
      () => _open(actorId, loungeId),
    );
    try {
      return await opening;
    } catch (_) {
      _repositories.remove(key);
      rethrow;
    }
  }

  Future<OfflineCashierRepository> _open(
    String actorId,
    String loungeId,
  ) async {
    final journal = await EncryptedCashierJournal.open(
      ownerId: actorId,
      loungeId: loungeId,
      keys: keys,
    );
    return OfflineCashierRepositoryImpl(
      journal: journal,
      commands: LocalCashierCommands(journal),
      synchronizer: CashierOutboxSynchronizer(
        journal: journal,
        transport: SupabaseCashierSyncTransport(client),
      ),
    );
  }

  @override
  Future<void> closeAll() async {
    final opening = List.of(_repositories.values);
    _repositories.clear();
    for (final repository in opening) {
      try {
        await (await repository).close();
      } catch (_) {}
    }
  }
}
