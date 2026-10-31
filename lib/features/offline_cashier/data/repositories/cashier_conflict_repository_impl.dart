import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cashier_conflict.dart';
import '../../domain/repositories/cashier_conflict_repository.dart';
import '../datasources/cashier_conflict_data_source.dart';

class CashierConflictRepositoryImpl implements CashierConflictRepository {
  final CashierConflictDataSource source;
  const CashierConflictRepositoryImpl(this.source);

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on PostgrestException catch (e) {
      return Left(
        ServerFailure(
          e.code == '42501' || e.code == '28000'
              ? 'offline_conflicts.denied'
              : 'offline_conflicts.failed',
        ),
      );
    } catch (_) {
      return const Left(ServerFailure('offline_conflicts.failed'));
    }
  }

  @override
  Future<Either<Failure, List<CashierConflict>>> load(
    String actorId,
    String loungeId,
  ) => _run(() => source.load(actorId, loungeId));

  @override
  Future<Either<Failure, void>> approve({
    required String actorId,
    required String loungeId,
    required String operationId,
    required String reviewId,
    required String reason,
  }) => _run(
    () => source.approve(
      actorId: actorId,
      loungeId: loungeId,
      operationId: operationId,
      reviewId: reviewId,
      reason: reason,
    ),
  );
}
