import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/tournament_entity.dart';
import '../repositories/tournament_repository.dart';

class UpdateTournamentParams extends Equatable {
  final TournamentEntity tournament;

  const UpdateTournamentParams({required this.tournament});

  @override
  List<Object?> get props => [tournament];
}

class UpdateTournamentUseCase implements UseCase<TournamentEntity, UpdateTournamentParams> {
  final TournamentRepository repository;

  UpdateTournamentUseCase(this.repository);

  @override
  Future<Either<Failure, TournamentEntity>> call(UpdateTournamentParams params) {
    return repository.updateTournament(params.tournament);
  }
}
