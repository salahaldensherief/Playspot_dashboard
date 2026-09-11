import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/tournament_repository.dart';

class CheckInParticipantParams extends Equatable {
  final String participantId;

  const CheckInParticipantParams({required this.participantId});

  @override
  List<Object?> get props => [participantId];
}

class CheckInParticipantUseCase implements UseCase<void, CheckInParticipantParams> {
  final TournamentRepository repository;

  CheckInParticipantUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CheckInParticipantParams params) {
    return repository.checkInParticipant(params.participantId);
  }
}
