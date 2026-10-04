import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/local_cashier_command.dart';
import '../../domain/entities/cashier_sync_result.dart';
import '../../domain/entities/cashier_connection_mode.dart';
import '../../domain/repositories/offline_cashier_repository.dart';
import '../datasources/local_cashier_commands.dart';
import '../datasources/cashier_outbox_synchronizer.dart';
import '../datasources/encrypted_cashier_journal.dart';
import '../datasources/cashier_authority_refresher.dart';
import '../datasources/cashier_bootstrap_refresher.dart';
import '../datasources/cashier_writer_releaser.dart';

class OfflineCashierRepositoryImpl implements OfflineCashierRepository {
  final EncryptedCashierJournal journal;
  final LocalCashierCommands commands;
  final CashierOutboxSynchronizer synchronizer;
  final CashierAuthorityRefresher? authorityRefresher;
  final CashierBootstrapRefresher? bootstrapRefresher;
  final CashierWriterReleaser? writerReleaser;
  final void Function()? _ensureActive;
  const OfflineCashierRepositoryImpl({
    required this.journal,
    required this.commands,
    required this.synchronizer,
    this.authorityRefresher,
    this.bootstrapRefresher,
    this.writerReleaser,
    void Function()? ensureActive,
  }) : _ensureActive = ensureActive;

  Future<Either<Failure, T>> _guard<T>(
    Future<T> Function() action,
    String fallback,
  ) async {
    try {
      _ensureActive?.call();
      final result = await action();
      _ensureActive?.call();
      return Right(result);
    } on StateError catch (error) {
      final key = error.message.toString();
      return Left(
        CacheFailure(key.startsWith('offline_cashier.') ? key : fallback),
      );
    } on FormatException catch (error) {
      return Left(
        CacheFailure(
          error.message.startsWith('offline_cashier.')
              ? error.message
              : fallback,
        ),
      );
    } catch (_) {
      return Left(CacheFailure(fallback));
    }
  }

  @override
  Future<void> close() async {
    writerReleaser?.stop();
    bootstrapRefresher?.stop();
    authorityRefresher?.stop();
    synchronizer.stop();
    await journal.close();
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> execute(
    LocalCashierCommand command,
  ) => _guard(
    () => commands.execute(command),
    'offline_cashier.operation_failed',
  );
  @override
  Future<Either<Failure, Map<String, dynamic>>> snapshot() =>
      _guard(journal.read, 'offline_cashier.storage_failed');
  @override
  Future<Either<Failure, Map<String, dynamic>>> bootstrap({
    required String deviceId,
    required CashierConnectionMode mode,
  }) => _guard(() {
    final refresher = bootstrapRefresher;
    if (refresher == null) {
      throw StateError('offline_cashier.bootstrap_unavailable');
    }
    return refresher.refresh(deviceId: deviceId, mode: mode);
  }, 'offline_cashier.bootstrap_unavailable');
  @override
  Future<Either<Failure, CashierSyncResult>> synchronize() =>
      _guard(synchronizer.synchronize, 'offline_cashier.sync_failed');

  @override
  Future<Either<Failure, Map<String, dynamic>>> releaseWriter() => _guard(() {
    final releaser = writerReleaser;
    if (releaser == null) {
      throw StateError('offline_cashier.release_unavailable');
    }
    return releaser.release();
  }, 'offline_cashier.release_unavailable');

  @override
  Future<Either<Failure, Map<String, dynamic>>> refreshAuthority({
    required String deviceId,
    required CashierConnectionMode mode,
  }) => _guard(() {
    final refresher = authorityRefresher;
    if (refresher == null) {
      throw StateError('offline_cashier.authority_unavailable');
    }
    return refresher.refresh(deviceId: deviceId, mode: mode);
  }, 'offline_cashier.authority_unavailable');
}
