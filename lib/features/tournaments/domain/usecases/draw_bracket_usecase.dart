import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/tournament_match_entity.dart';
import '../repositories/tournament_repository.dart';

class DrawBracketParams extends Equatable {
  final String tournamentId;

  const DrawBracketParams({required this.tournamentId});

  @override
  List<Object?> get props => [tournamentId];
}

class DrawBracketUseCase implements UseCase<List<TournamentMatchEntity>, DrawBracketParams> {
  final TournamentRepository repository;

  DrawBracketUseCase(this.repository);

  @override
  Future<Either<Failure, List<TournamentMatchEntity>>> call(DrawBracketParams params) {
    return repository.drawBracket(params.tournamentId);
  }
}
