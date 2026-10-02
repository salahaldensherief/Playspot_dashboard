import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/kyc_repository.dart';
import 'submit_kyc_params.dart';

class SubmitKycUseCase implements UseCase<void, SubmitKycParams> {
  final KycRepository repository;

  SubmitKycUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SubmitKycParams params) {
    return repository.submitKyc(
      userId: params.userId,
      loungeId: params.loungeId,
      idCardBytes: params.idCardBytes,
      idCardName: params.idCardName,
      businessDocBytes: params.businessDocBytes,
      businessDocName: params.businessDocName,
    );
  }
}
