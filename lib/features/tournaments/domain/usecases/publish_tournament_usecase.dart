import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/tournament_repository.dart';

class PublishTournamentParams extends Equatable {
  final String tournamentId;

  const PublishTournamentParams({required this.tournamentId});

  @override
  List<Object?> get props => [tournamentId];
}

class PublishTournamentUseCase implements UseCase<void, PublishTournamentParams> {
  final TournamentRepository repository;

  PublishTournamentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(PublishTournamentParams params) {
    return repository.publishTournament(params.tournamentId);
  }
}
