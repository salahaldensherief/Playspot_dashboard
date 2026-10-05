import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../domain/repositories/cashier_conflict_repository.dart';
import 'cashier_conflict_state.dart';

class CashierConflictCubit extends Cubit<CashierConflictState> {
  final CashierConflictRepository repository;
  String? _actor;
  String? _lounge;
  int _epoch = 0;
  final Map<String, ({String id, String reason})> _reviews = {};

  CashierConflictCubit(this.repository) : super(const CashierConflictState());

  Future<void> load(String actor, String lounge) async {
    if (_actor != actor || _lounge != lounge) {
      _epoch++;
      _reviews.clear();
      _actor = actor;
      _lounge = lounge;
      emit(const CashierConflictState());
    } else if (state.busy || state.status == CashierConflictStatus.loading) {
      return;
    }
    final epoch = ++_epoch;
    emit(const CashierConflictState(status: CashierConflictStatus.loading));
    final result = await repository.load(actor, lounge);
    if (isClosed || epoch != _epoch) return;
    result.fold(
      (f) => emit(
        CashierConflictState(
          status: CashierConflictStatus.failure,
          error: f.message,
        ),
      ),
      (items) => emit(
        CashierConflictState(
          status: CashierConflictStatus.ready,
          conflicts: items,
        ),
      ),
    );
  }

  Future<void> approve(String operationId, String reason) async {
    final actor = _actor;
    final lounge = _lounge;
    if (actor == null ||
        lounge == null ||
        state.busy ||
        isClosed ||
        state.status != CashierConflictStatus.ready) {
      return;
    }
    final eligible = state.conflicts.any(
      (c) => c.operationId == operationId && !c.retryPending,
    );
    final text = reason.trim();
    if (!eligible) return;
    if (text.runes.length < 10 || text.runes.length > 1000) {
      emit(
        CashierConflictState(
          status: state.status,
          conflicts: state.conflicts,
          error: 'offline_conflicts.reason_invalid',
        ),
      );
      return;
    }
    final saved = _reviews[operationId];
    if (saved != null && saved.reason != text) {
      emit(
        CashierConflictState(
          status: state.status,
          conflicts: state.conflicts,
          error: 'offline_conflicts.retry_same_reason',
        ),
      );
      return;
    }
    final review = _reviews.putIfAbsent(
      operationId,
      () => (id: const Uuid().v4(), reason: text),
    );
    final epoch = _epoch;
    emit(
      CashierConflictState(
        status: state.status,
        conflicts: state.conflicts,
        busy: true,
      ),
    );
    final result = await repository.approve(
      actorId: actor,
      loungeId: lounge,
      operationId: operationId,
      reviewId: review.id,
      reason: review.reason,
    );
    if (isClosed || epoch != _epoch) return;
    String? error;
    result.fold((f) => error = f.message, (_) => null);
    emit(
      CashierConflictState(
        status: CashierConflictStatus.ready,
        conflicts: state.conflicts,
        error: error,
      ),
    );
    if (error == null) {
      _reviews.remove(operationId);
      await load(actor, lounge);
    }
  }

  @override
  Future<void> close() {
    _epoch++;
    return super.close();
  }
}
