import 'package:equatable/equatable.dart';
import '../domain/entities/tournament_match_entity.dart';

enum TournamentMatchesStatus { initial, loading, success, actionSuccess, failure }

class TournamentMatchesState extends Equatable {
  final TournamentMatchesStatus status;
  final List<TournamentMatchEntity> matches;
  final List<TournamentMatchEntity> disputedMatches;
  final String? errorMessage;
  final String? successMessage;

  const TournamentMatchesState({
    this.status = TournamentMatchesStatus.initial,
    this.matches = const [],
    this.disputedMatches = const [],
    this.errorMessage,
    this.successMessage,
  });

  TournamentMatchesState copyWith({
    TournamentMatchesStatus? status,
    List<TournamentMatchEntity>? matches,
    List<TournamentMatchEntity>? disputedMatches,
    String? errorMessage,
    String? successMessage,
  }) {
    return TournamentMatchesState(
      status: status ?? this.status,
      matches: matches ?? this.matches,
      disputedMatches: disputedMatches ?? this.disputedMatches,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        matches,
        disputedMatches,
        errorMessage,
        successMessage,
      ];
}
