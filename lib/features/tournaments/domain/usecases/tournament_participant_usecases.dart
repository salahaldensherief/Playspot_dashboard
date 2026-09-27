import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/tournament_participant_entity.dart';
import '../repositories/tournament_repository.dart';

class GetTournamentParticipantsUseCase
    implements UseCase<List<TournamentParticipantEntity>, String> {
  final TournamentRepository repository;

  GetTournamentParticipantsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TournamentParticipantEntity>>> call(String tournamentId) {
    return repository.getParticipants(tournamentId);
  }
}

class ApproveParticipantPaymentUseCase implements UseCase<void, String> {
  final TournamentRepository repository;

  ApproveParticipantPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String participantId) {
    return repository.approvePayment(participantId);
  }
}

class RejectPaymentParams extends Equatable {
  final String participantId;
  final String reason;

  const RejectPaymentParams({required this.participantId, required this.reason});

  @override
  List<Object?> get props => [participantId, reason];
}

class RejectParticipantPaymentUseCase implements UseCase<void, RejectPaymentParams> {
  final TournamentRepository repository;

  RejectParticipantPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RejectPaymentParams params) {
    return repository.rejectPayment(params.participantId, params.reason);
  }
}

class RecordCashPaymentUseCase implements UseCase<void, String> {
  final TournamentRepository repository;

  RecordCashPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String participantId) {
    return repository.recordCashPayment(participantId);
  }
}

class PromoteWaitlistUseCase implements UseCase<void, String> {
  final TournamentRepository repository;

  PromoteWaitlistUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String tournamentId) {
    return repository.promoteWaitlist(tournamentId);
  }
}

class CheckInParticipantUseCase implements UseCase<void, String> {
  final TournamentRepository repository;

  CheckInParticipantUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String participantId) {
    return repository.checkInParticipant(participantId);
  }
}

class WithdrawParticipantUseCase implements UseCase<void, String> {
  final TournamentRepository repository;

  WithdrawParticipantUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String participantId) {
    return repository.withdrawParticipant(participantId);
  }
}
