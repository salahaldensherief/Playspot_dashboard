import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/tournament_repository.dart';

class ApprovePaymentParams extends Equatable {
  final String participantId;

  const ApprovePaymentParams({required this.participantId});

  @override
  List<Object?> get props => [participantId];
}

class ApprovePaymentUseCase implements UseCase<void, ApprovePaymentParams> {
  final TournamentRepository repository;

  ApprovePaymentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ApprovePaymentParams params) {
    return repository.approvePayment(params.participantId);
  }
}
