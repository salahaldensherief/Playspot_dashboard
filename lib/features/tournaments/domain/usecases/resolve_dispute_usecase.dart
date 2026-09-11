import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/tournament_repository.dart';

class ResolveDisputeParams extends Equatable {
  final String matchId;
  final String winnerId;
  final int p1Score;
  final int p2Score;
  final String resolutionNotes;

  const ResolveDisputeParams({
    required this.matchId,
    required this.winnerId,
    required this.p1Score,
    required this.p2Score,
    required this.resolutionNotes,
  });

  @override
  List<Object?> get props => [
        matchId,
        winnerId,
        p1Score,
        p2Score,
        resolutionNotes,
      ];
}

class ResolveDisputeUseCase implements UseCase<void, ResolveDisputeParams> {
  final TournamentRepository repository;

  ResolveDisputeUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResolveDisputeParams params) {
    return repository.resolveDispute(
      params.matchId,
      winnerId: params.winnerId,
      p1Score: params.p1Score,
      p2Score: params.p2Score,
      resolutionNotes: params.resolutionNotes,
    );
  }
}
