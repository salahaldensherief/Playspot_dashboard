import 'package:equatable/equatable.dart';
import '../domain/entities/tournament_participant_entity.dart';

enum TournamentParticipantsStatus { initial, loading, success, actionSuccess, failure }

class TournamentParticipantsState extends Equatable {
  final TournamentParticipantsStatus status;
  final List<TournamentParticipantEntity> participants;
  final String? errorMessage;
  final String? successMessage;

  const TournamentParticipantsState({
    this.status = TournamentParticipantsStatus.initial,
    this.participants = const [],
    this.errorMessage,
    this.successMessage,
  });

  TournamentParticipantsState copyWith({
    TournamentParticipantsStatus? status,
    List<TournamentParticipantEntity>? participants,
    String? errorMessage,
    String? successMessage,
  }) {
    return TournamentParticipantsState(
      status: status ?? this.status,
      participants: participants ?? this.participants,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        participants,
        errorMessage,
        successMessage,
      ];
}
