import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/tournament_match_entity.dart';
import '../repositories/tournament_repository.dart';

class GetMatchesParams extends Equatable {
  final String tournamentId;

  const GetMatchesParams({required this.tournamentId});

  @override
  List<Object?> get props => [tournamentId];
}

class GetMatchesUseCase implements UseCase<List<TournamentMatchEntity>, GetMatchesParams> {
  final TournamentRepository repository;

  GetMatchesUseCase(this.repository);

  @override
  Future<Either<Failure, List<TournamentMatchEntity>>> call(GetMatchesParams params) {
    return repository.getMatches(params.tournamentId);
  }
}
