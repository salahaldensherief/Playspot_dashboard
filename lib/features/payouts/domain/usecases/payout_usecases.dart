import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/payout_entity.dart';
import '../repositories/payout_repository.dart';

class GetPendingPayoutsOverviewUseCase implements UseCase<List<PendingPayoutOverview>, NoParams> {
  final PayoutRepository repository;

  GetPendingPayoutsOverviewUseCase(this.repository);

  @override
  Future<Either<Failure, List<PendingPayoutOverview>>> call(NoParams params) {
    return repository.getPendingPayoutsOverview();
  }
}

class GetAllPayoutsUseCase implements UseCase<List<PayoutEntity>, NoParams> {
  final PayoutRepository repository;

  GetAllPayoutsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PayoutEntity>>> call(NoParams params) {
    return repository.getAllPayouts();
  }
}

class CreatePayoutParams extends Equatable {
  final String loungeId;
  final String periodStart;
  final String periodEnd;

  const CreatePayoutParams({
    required this.loungeId,
    required this.periodStart,
    required this.periodEnd,
  });

  @override
  List<Object?> get props => [loungeId, periodStart, periodEnd];
}

class CreatePayoutUseCase implements UseCase<Map<String, dynamic>, CreatePayoutParams> {
  final PayoutRepository repository;

  CreatePayoutUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(CreatePayoutParams params) {
    return repository.createPayout(
      loungeId: params.loungeId,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
    );
  }
}

class ApprovePayoutParams extends Equatable {
  final String payoutId;
  final String? notes;

  const ApprovePayoutParams({required this.payoutId, this.notes});

  @override
  List<Object?> get props => [payoutId, notes];
}

class ApprovePayoutUseCase implements UseCase<void, ApprovePayoutParams> {
  final PayoutRepository repository;

  ApprovePayoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ApprovePayoutParams params) {
    return repository.approvePayout(payoutId: params.payoutId, notes: params.notes);
  }
}

class StartPayoutProcessingUseCase implements UseCase<void, String> {
  final PayoutRepository repository;

  StartPayoutProcessingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String payoutId) {
    return repository.startPayoutProcessing(payoutId: payoutId);
  }
}

class CompletePayoutParams extends Equatable {
  final String payoutId;
  final String transferMethod;
  final String transferReference;
  final String? receiptUrl;
  final String? notes;

  const CompletePayoutParams({
    required this.payoutId,
    required this.transferMethod,
    required this.transferReference,
    this.receiptUrl,
    this.notes,
  });

  @override
  List<Object?> get props => [payoutId, transferMethod, transferReference, receiptUrl, notes];
}

class CompletePayoutUseCase implements UseCase<void, CompletePayoutParams> {
  final PayoutRepository repository;

  CompletePayoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CompletePayoutParams params) {
    return repository.completePayout(
      payoutId: params.payoutId,
      transferMethod: params.transferMethod,
      transferReference: params.transferReference,
      receiptUrl: params.receiptUrl,
      notes: params.notes,
    );
  }
}

class MarkPayoutPaidParams extends Equatable {
  final String payoutId;
  final String? notes;

  const MarkPayoutPaidParams({required this.payoutId, this.notes});

  @override
  List<Object?> get props => [payoutId, notes];
}

class MarkPayoutPaidUseCase implements UseCase<void, MarkPayoutPaidParams> {
  final PayoutRepository repository;

  MarkPayoutPaidUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkPayoutPaidParams params) {
    return repository.markPayoutPaid(payoutId: params.payoutId, notes: params.notes);
  }
}

class FailPayoutParams extends Equatable {
  final String payoutId;
  final String reason;

  const FailPayoutParams({required this.payoutId, required this.reason});

  @override
  List<Object?> get props => [payoutId, reason];
}

class FailPayoutUseCase implements UseCase<void, FailPayoutParams> {
  final PayoutRepository repository;

  FailPayoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(FailPayoutParams params) {
    return repository.failPayout(payoutId: params.payoutId, reason: params.reason);
  }
}

class CancelPayoutParams extends Equatable {
  final String payoutId;
  final String reason;

  const CancelPayoutParams({required this.payoutId, required this.reason});

  @override
  List<Object?> get props => [payoutId, reason];
}

class CancelPayoutUseCase implements UseCase<void, CancelPayoutParams> {
  final PayoutRepository repository;

  CancelPayoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CancelPayoutParams params) {
    return repository.cancelPayout(payoutId: params.payoutId, reason: params.reason);
  }
}

class ResolvePayoutReviewParams extends Equatable {
  final String payoutId;
  final String resolution;
  final String reason;

  const ResolvePayoutReviewParams({
    required this.payoutId,
    required this.resolution,
    required this.reason,
  });

  @override
  List<Object?> get props => [payoutId, resolution, reason];
}

class ResolvePayoutReviewUseCase implements UseCase<void, ResolvePayoutReviewParams> {
  final PayoutRepository repository;

  ResolvePayoutReviewUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResolvePayoutReviewParams params) {
    return repository.resolvePayoutReview(
      payoutId: params.payoutId,
      resolution: params.resolution,
      reason: params.reason,
    );
  }
}

class GetPayoutDetailsUseCase implements UseCase<Map<String, dynamic>, String> {
  final PayoutRepository repository;

  GetPayoutDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(String payoutId) {
    return repository.getPayoutDetails(payoutId: payoutId);
  }
}

class GetPayoutsByLoungeUseCase implements UseCase<List<PayoutEntity>, String> {
  final PayoutRepository repository;

  GetPayoutsByLoungeUseCase(this.repository);

  @override
  Future<Either<Failure, List<PayoutEntity>>> call(String loungeId) {
    return repository.getPayoutsByLounge(loungeId);
  }
}
