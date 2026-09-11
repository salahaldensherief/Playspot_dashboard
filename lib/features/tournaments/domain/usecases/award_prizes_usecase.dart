import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/tournament_repository.dart';

class AwardPrizesParams extends Equatable {
  final String tournamentId;

  const AwardPrizesParams({required this.tournamentId});

  @override
  List<Object?> get props => [tournamentId];
}

class AwardPrizesUseCase implements UseCase<Map<String, dynamic>, AwardPrizesParams> {
  final TournamentRepository repository;

  AwardPrizesUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(AwardPrizesParams params) {
    return repository.awardPrizes(params.tournamentId);
  }
}
