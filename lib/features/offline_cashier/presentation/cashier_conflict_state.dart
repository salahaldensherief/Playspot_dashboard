import 'package:equatable/equatable.dart';
import '../domain/entities/cashier_conflict.dart';

enum CashierConflictStatus { initial, loading, ready, failure }

class CashierConflictState extends Equatable {
  final CashierConflictStatus status;
  final List<CashierConflict> conflicts;
  final bool busy;
  final String? error;

  const CashierConflictState({
    this.status = CashierConflictStatus.initial,
    this.conflicts = const [],
    this.busy = false,
    this.error,
  });

  @override
  List<Object?> get props => [status, conflicts, busy, error];
}
