import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/offline_cashier_repository.dart';
import '../repositories/offline_cashier_repository_impl.dart';
import 'cashier_store_factory.dart';
import 'offline_key_vault.dart';
import 'encrypted_cashier_journal.dart';
import 'local_cashier_commands.dart';
import 'cashier_outbox_synchronizer.dart';
import 'supabase_cashier_sync_transport.dart';
import 'supabase_cashier_authority_transport.dart';
import 'cashier_authority_refresher.dart';
import 'cashier_authority_store.dart';
import 'cashier_bootstrap_store.dart';
import 'cashier_bootstrap_refresher.dart';
import 'supabase_cashier_bootstrap_transport.dart';

class CashierStoreFactoryImpl implements CashierStoreFactory {
  final OfflineKeyVault keys;
  final SupabaseClient client;
  final DateTime Function() _clock;
  final Map<String, Future<OfflineCashierRepository>> _repositories = {};
  late final StreamSubscription<AuthState> _authSubscription;
  Future<void> _closing = Future.value();
  int _epoch = 0;
  String? _actorId;
  bool _disposed = false;
  CashierStoreFactoryImpl({
    required this.keys,
    required this.client,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _actorId = client.auth.currentUser?.id;
    _authSubscription = client.auth.onAuthStateChange.listen(
      _onAuthChanged,
      onError: (Object error) => _checkCurrentIdentity(),
    );
  }

  void _onAuthChanged(AuthState state) {
    final actorId = state.session?.user.id;
    if (state.event == AuthChangeEvent.signedOut ||
        state.event == AuthChangeEvent.signedIn ||
        actorId != _actorId) {
      _actorId = actorId;
      unawaited(closeAll());
    }
  }

  void _checkCurrentIdentity() {
    final actorId = client.auth.currentUser?.id;
    if (actorId != _actorId) {
      _actorId = actorId;
      unawaited(closeAll());
    }
  }

  void _ensureScope(int epoch, String actorId) {
    _checkCurrentIdentity();
    if (_disposed || epoch != _epoch) {
      throw StateError('offline_cashier.journal_closed');
    }
    if (client.auth.currentUser?.id != actorId) {
      throw StateError('offline_cashier.permission_denied');
    }
  }

  @override
  Future<OfflineCashierRepository> open({
    required String actorId,
    required String loungeId,
  }) async {
    Future<void> closing;
    do {
      closing = _closing;
      await closing;
    } while (!identical(closing, _closing));
    if (_disposed) throw StateError('offline_cashier.journal_closed');
    if (client.auth.currentUser?.id != actorId) {
      throw StateError('offline_cashier.permission_denied');
    }
    final key = '$actorId/$loungeId';
    final epoch = _epoch;
    final opening = _repositories.putIfAbsent(
      key,
      () => _open(actorId, loungeId, epoch),
    );
    try {
      final repository = await opening;
      _ensureScope(epoch, actorId);
      return repository;
    } catch (_) {
      if (identical(_repositories[key], opening)) {
        _repositories.remove(key);
      }
      rethrow;
    }
  }

  Future<OfflineCashierRepository> _open(
    String actorId,
    String loungeId,
    int epoch,
  ) async {
    final journal = await EncryptedCashierJournal.open(
      ownerId: actorId,
      loungeId: loungeId,
      keys: keys,
    );
    final authorityStore = CashierAuthorityStore(
      journal,
      clock: _clock,
      ensureActive: () => _ensureScope(epoch, actorId),
    );
    return OfflineCashierRepositoryImpl(
      ensureActive: () => _ensureScope(epoch, actorId),
      journal: journal,
      commands: LocalCashierCommands(
        journal,
        clock: _clock,
        ensureActive: () => _ensureScope(epoch, actorId),
        requireBootstrap: true,
      ),
      authorityRefresher: CashierAuthorityRefresher(
        transport: SupabaseCashierAuthorityTransport(client, actorId),
        store: authorityStore,
      ),
      bootstrapRefresher: CashierBootstrapRefresher(
        transport: SupabaseCashierBootstrapTransport(client, actorId),
        store: CashierBootstrapStore(authorityStore),
      ),
      synchronizer: CashierOutboxSynchronizer(
        journal: journal,
        transport: SupabaseCashierSyncTransport(client),
        ensureActive: () => _ensureScope(epoch, actorId),
      ),
    );
  }

  @override
  Future<void> closeAll() {
    _epoch++;
    final opening = List.of(_repositories.values);
    _repositories.clear();
    return _closing = _closing.then((_) => _closeRepositories(opening));
  }

  Future<void> _closeRepositories(
    List<Future<OfflineCashierRepository>> opening,
  ) async {
    for (final repository in opening) {
      try {
        await (await repository).close();
      } catch (_) {}
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _authSubscription.cancel();
    await closeAll();
  }
}
