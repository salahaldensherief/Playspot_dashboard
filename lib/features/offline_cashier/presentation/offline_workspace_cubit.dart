import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../domain/repositories/cashier_workspace_store.dart';
import '../domain/repositories/offline_cashier_repository.dart';
import '../domain/entities/local_cashier_command.dart';
import '../domain/entities/cashier_connection_mode.dart';
import 'offline_workspace_state.dart';

class OfflineWorkspaceCubit extends Cubit<OfflineWorkspaceState> {
  final CashierWorkspaceStore store;
  final DateTime Function() clock;
  OfflineCashierRepository? _repository;
  String? _actor, _lounge, _device;
  int _epoch = 0;
  OfflineWorkspaceCubit(this.store, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now,
      super(const OfflineWorkspaceState());
  Future<void> load(String actor, String lounge) async {
    if (_actor == actor && _lounge == lounge && _repository != null) return;
    final epoch = ++_epoch;
    _actor = actor;
    _lounge = lounge;
    _repository = null;
    emit(const OfflineWorkspaceState(status: OfflineWorkspaceStatus.loading));
    try {
      if (actor.isEmpty || lounge.isEmpty) {
        throw StateError('offline_cashier.permission_denied');
      }
      final device = await store.deviceId();
      final repository = await store.open(actor, lounge);
      if (isClosed || epoch != _epoch) return;
      _device = device;
      _repository = repository;
      await _read(epoch);
    } catch (_) {
      if (!isClosed && epoch == _epoch) {
        emit(
          const OfflineWorkspaceState(
            status: OfflineWorkspaceStatus.failure,
            error: 'offline_cashier.storage_failed',
          ),
        );
      }
    }
  }

  Future<void> _read(int epoch) async {
    final result = await _repository?.snapshot();
    if (result == null || isClosed || epoch != _epoch) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: OfflineWorkspaceStatus.failure,
          error: failure.message,
          busy: false,
        ),
      ),
      (snapshot) => emit(
        state.copyWith(
          status: OfflineWorkspaceStatus.ready,
          snapshot: Map<String, dynamic>.from(
            jsonDecode(jsonEncode(snapshot)) as Map,
          ),
          busy: false,
        ),
      ),
    );
  }

  Future<void> _run(
    Future<Either<Failure, dynamic>> Function(OfflineCashierRepository) action,
  ) async {
    final repo = _repository;
    if (repo == null || state.busy || isClosed) return;
    final epoch = _epoch;
    emit(state.copyWith(busy: true));
    String? error;
    try {
      final result = await action(repo);
      result.fold((failure) => error = failure.message, (_) => null);
    } catch (_) {
      error = 'offline_cashier.operation_failed';
    }
    if (isClosed || epoch != _epoch) return;
    await _read(epoch);
    if (!isClosed && epoch == _epoch && error != null) {
      emit(state.copyWith(error: error, busy: false));
    }
  }

  Future<void> prepare() => _run(
    (repo) => repo.bootstrap(
      deviceId: _device ?? '',
      mode: CashierConnectionMode.offline,
    ),
  );
  Future<void> synchronize() => _run((repo) => repo.synchronize());
  Future<void> release() => _run((repo) => repo.releaseWriter());
  Future<void> resumeOnline() => _run((repo) async {
    final sync = await repo.synchronize();
    if (sync.isLeft()) return sync;
    final snapshot = await repo.snapshot();
    return snapshot.fold((failure) => Left(failure), (value) async {
      if ((value['outbox'] as List? ?? []).isNotEmpty ||
          (value['sync_conflicts'] as Map? ?? {}).isNotEmpty) {
        return const Left(
          CacheFailure('offline_cashier.release_pending_operations'),
        );
      }
      return repo.bootstrap(
        deviceId: _device ?? '',
        mode: CashierConnectionMode.online,
      );
    });
  });
  Future<void> execute(
    LocalCashierCommandKind kind,
    String bookingId,
    Map<String, dynamic> payload,
  ) => _run((repo) {
    final authority = state.snapshot['authority'] as Map?;
    final shift = state.snapshot['shift'] as Map?;
    if (!state.canOperate || authority == null || shift == null) {
      return Future.value(
        const Left(CacheFailure('offline_cashier.bootstrap_required')),
      );
    }
    return repo.execute(
      LocalCashierCommand(
        id: const Uuid().v4(),
        bookingId: bookingId,
        actorId: _actor ?? '',
        loungeId: _lounge ?? '',
        deviceId: _device ?? '',
        permitId: authority['permit_id'] as String? ?? '',
        shiftId: shift['id'] as String? ?? '',
        occurredAt: clock().toUtc(),
        kind: kind,
        payload: payload,
      ),
    );
  });
  @override
  Future<void> close() {
    _epoch++;
    return super.close();
  }
}
