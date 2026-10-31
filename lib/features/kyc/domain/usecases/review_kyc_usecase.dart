import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/kyc_repository.dart';
import 'review_kyc_params.dart';

class ReviewKycUseCase implements UseCase<void, ReviewKycParams> {
  final KycRepository repository;

  ReviewKycUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ReviewKycParams params) {
    return repository.reviewKyc(
      requestId: params.requestId,
      revision: params.revision,
      approve: params.approve,
      notes: params.notes,
    );
  }
}
