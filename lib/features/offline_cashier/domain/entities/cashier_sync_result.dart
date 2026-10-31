import 'package:equatable/equatable.dart';

class CashierSyncResult extends Equatable {
  final int appliedCount;
  final int pendingCount;
  final String? blockedOperationId;
  const CashierSyncResult({
    required this.appliedCount,
    required this.pendingCount,
    this.blockedOperationId,
  });
  @override
  List<Object?> get props => [appliedCount, pendingCount, blockedOperationId];
}
