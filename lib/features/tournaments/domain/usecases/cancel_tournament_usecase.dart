import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/tournament_repository.dart';

class CancelTournamentParams extends Equatable {
  final String tournamentId;
  final String reason;

  const CancelTournamentParams({
    required this.tournamentId,
    required this.reason,
  });

  @override
  List<Object?> get props => [tournamentId, reason];
}

class CancelTournamentUseCase implements UseCase<void, CancelTournamentParams> {
  final TournamentRepository repository;

  CancelTournamentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CancelTournamentParams params) {
    return repository.cancelTournament(params.tournamentId, params.reason);
  }
}
