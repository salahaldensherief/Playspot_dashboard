import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/tournament_repository.dart';

class CompleteTournamentParams extends Equatable {
  final String tournamentId;

  const CompleteTournamentParams({required this.tournamentId});

  @override
  List<Object?> get props => [tournamentId];
}

class CompleteTournamentUseCase implements UseCase<void, CompleteTournamentParams> {
  final TournamentRepository repository;

  CompleteTournamentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CompleteTournamentParams params) {
    return repository.completeTournament(params.tournamentId);
  }
}
