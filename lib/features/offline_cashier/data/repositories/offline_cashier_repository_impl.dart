import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/local_cashier_command.dart';
import '../../domain/entities/cashier_sync_result.dart';
import '../../domain/repositories/offline_cashier_repository.dart';
import '../datasources/local_cashier_commands.dart';
import '../datasources/cashier_outbox_synchronizer.dart';
import '../datasources/encrypted_cashier_journal.dart';

class OfflineCashierRepositoryImpl implements OfflineCashierRepository {
  final EncryptedCashierJournal journal;
  final LocalCashierCommands commands;
  final CashierOutboxSynchronizer synchronizer;
  const OfflineCashierRepositoryImpl({
    required this.journal,
    required this.commands,
    required this.synchronizer,
  });

  Future<Either<Failure, T>> _guard<T>(
    Future<T> Function() action,
    String fallback,
  ) async {
    try {
      return Right(await action());
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
  Future<Either<Failure, CashierSyncResult>> synchronize() =>
      _guard(synchronizer.synchronize, 'offline_cashier.sync_failed');
}
