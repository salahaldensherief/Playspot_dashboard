import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../domain/entities/tournament_entity.dart';
import 'tournament_state.dart';

typedef TournamentActionResult = Future<Either<Failure, void>>;

class TournamentStateMutator {
  static TournamentState applyStatusUpdate({
    required TournamentState state,
    required String tournamentId,
    required TournamentStatus newStatus,
    required String successMessage,
  }) {
    final updatedList = state.tournaments.map((t) {
      return t.id == tournamentId ? t.copyWith(status: newStatus) : t;
    }).toList();
    final updatedSelected = state.selectedTournament?.id == tournamentId
        ? state.selectedTournament?.copyWith(status: newStatus)
        : state.selectedTournament;

    return state.copyWith(
      status: TournamentCubitStatus.actionSuccess,
      tournaments: updatedList,
      selectedTournament: updatedSelected,
      successMessage: successMessage,
    );
  }

  static TournamentState applyDeletion({
    required TournamentState state,
    required String tournamentId,
    required String successMessage,
  }) {
    final list = state.tournaments.where((t) => t.id != tournamentId).toList();
    return state.copyWith(
      status: TournamentCubitStatus.actionSuccess,
      tournaments: list,
      clearSelectedTournament: state.selectedTournament?.id == tournamentId,
      successMessage: successMessage,
    );
  }

  static TournamentState applyFailure({
    required TournamentState state,
    required Failure failure,
  }) {
    return state.copyWith(
      status: TournamentCubitStatus.failure,
      errorMessage: failure.message,
    );
  }
}
