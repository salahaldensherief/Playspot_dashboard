import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/tournament_repository.dart';

class DeleteDraftTournamentParams extends Equatable {
  final String tournamentId;

  const DeleteDraftTournamentParams({required this.tournamentId});

  @override
  List<Object?> get props => [tournamentId];
}

class DeleteDraftTournamentUseCase implements UseCase<void, DeleteDraftTournamentParams> {
  final TournamentRepository repository;

  DeleteDraftTournamentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteDraftTournamentParams params) {
    return repository.deleteDraftTournament(params.tournamentId);
  }
}
