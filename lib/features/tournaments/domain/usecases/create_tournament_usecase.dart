import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/tournament_entity.dart';
import '../repositories/tournament_repository.dart';

class CreateTournamentParams extends Equatable {
  final TournamentEntity tournament;

  const CreateTournamentParams({required this.tournament});

  @override
  List<Object?> get props => [tournament];
}

class CreateTournamentUseCase implements UseCase<TournamentEntity, CreateTournamentParams> {
  final TournamentRepository repository;

  CreateTournamentUseCase(this.repository);

  @override
  Future<Either<Failure, TournamentEntity>> call(CreateTournamentParams params) {
    return repository.createTournament(params.tournament);
  }
}
