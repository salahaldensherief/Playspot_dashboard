import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/tournament_repository.dart';

class RejectPaymentParams extends Equatable {
  final String participantId;
  final String reason;

  const RejectPaymentParams({
    required this.participantId,
    required this.reason,
  });

  @override
  List<Object?> get props => [participantId, reason];
}

class RejectPaymentUseCase implements UseCase<void, RejectPaymentParams> {
  final TournamentRepository repository;

  RejectPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RejectPaymentParams params) {
    return repository.rejectPayment(params.participantId, params.reason);
  }
}
