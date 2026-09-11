import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/tournament_participant_entity.dart';
import '../repositories/tournament_repository.dart';

class GetParticipantsParams extends Equatable {
  final String tournamentId;

  const GetParticipantsParams({required this.tournamentId});

  @override
  List<Object?> get props => [tournamentId];
}

class GetParticipantsUseCase implements UseCase<List<TournamentParticipantEntity>, GetParticipantsParams> {
  final TournamentRepository repository;

  GetParticipantsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TournamentParticipantEntity>>> call(GetParticipantsParams params) {
    return repository.getParticipants(params.tournamentId);
  }
}
