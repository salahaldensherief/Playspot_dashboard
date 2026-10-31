import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/kyc_repository.dart';
import '../entities/kyc_request.dart';

class GetPendingKycReviewsUseCase
    implements UseCase<List<KycRequest>, NoParams> {
  final KycRepository repository;

  GetPendingKycReviewsUseCase(this.repository);

  @override
  Future<Either<Failure, List<KycRequest>>> call(NoParams params) {
    return repository.getPendingReviews();
  }
}
