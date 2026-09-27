import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/kyc_request.dart';
import '../repositories/kyc_repository.dart';

class SubmitKycParams extends Equatable {
  final String userId;
  final Uint8List idCardBytes;
  final String idCardName;
  final Uint8List? businessDocBytes;
  final String? businessDocName;

  const SubmitKycParams({
    required this.userId,
    required this.idCardBytes,
    required this.idCardName,
    this.businessDocBytes,
    this.businessDocName,
  });

  @override
  List<Object?> get props => [userId, idCardBytes, idCardName, businessDocBytes, businessDocName];
}

class SubmitKycUseCase implements UseCase<void, SubmitKycParams> {
  final KycRepository repository;

  SubmitKycUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SubmitKycParams params) {
    return repository.submitKyc(
      userId: params.userId,
      idCardBytes: params.idCardBytes,
      idCardName: params.idCardName,
      businessDocBytes: params.businessDocBytes,
      businessDocName: params.businessDocName,
    );
  }
}

class GetPendingKycReviewsUseCase implements UseCase<List<KycRequest>, NoParams> {
  final KycRepository repository;

  GetPendingKycReviewsUseCase(this.repository);

  @override
  Future<Either<Failure, List<KycRequest>>> call(NoParams params) {
    return repository.getPendingReviews();
  }
}

class ReviewKycParams extends Equatable {
  final String userId;
  final bool approve;
  final String? notes;

  const ReviewKycParams({
    required this.userId,
    required this.approve,
    this.notes,
  });

  @override
  List<Object?> get props => [userId, approve, notes];
}

class ReviewKycUseCase implements UseCase<void, ReviewKycParams> {
  final KycRepository repository;

  ReviewKycUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ReviewKycParams params) {
    return repository.reviewKyc(
      userId: params.userId,
      approve: params.approve,
      notes: params.notes,
    );
  }
}
