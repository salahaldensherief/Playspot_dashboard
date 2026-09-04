import 'package:equatable/equatable.dart';
import '../domain/entities/lounge_stats_entity.dart';

enum LoungeStatsStatus { initial, loading, success, failure }

class LoungeStatsState extends Equatable {
  final LoungeStatsStatus status;
  final LoungeStatsEntity? stats;
  final String? errorMessage;

  const LoungeStatsState({
    this.status = LoungeStatsStatus.initial,
    this.stats,
    this.errorMessage,
  });

  LoungeStatsState copyWith({
    LoungeStatsStatus? status,
    LoungeStatsEntity? stats,
    String? errorMessage,
  }) {
    return LoungeStatsState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, stats, errorMessage];
}
