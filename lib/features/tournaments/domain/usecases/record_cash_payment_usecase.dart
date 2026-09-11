import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/tournament_repository.dart';

class RecordCashPaymentParams extends Equatable {
  final String participantId;

  const RecordCashPaymentParams({required this.participantId});

  @override
  List<Object?> get props => [participantId];
}

class RecordCashPaymentUseCase implements UseCase<void, RecordCashPaymentParams> {
  final TournamentRepository repository;

  RecordCashPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RecordCashPaymentParams params) {
    return repository.recordCashPayment(params.participantId);
  }
}
