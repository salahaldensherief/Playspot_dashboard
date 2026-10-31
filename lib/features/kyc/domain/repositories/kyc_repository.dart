import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/kyc_request.dart';
import 'dart:typed_data';

abstract class KycRepository {
  Future<Either<Failure, void>> submitKyc({
    required String userId,
    required String loungeId,
    required Uint8List idCardBytes,
    required String idCardName,
    Uint8List? businessDocBytes,
    String? businessDocName,
  });

  Future<Either<Failure, List<KycRequest>>> getPendingReviews();

  Future<Either<Failure, void>> reviewKyc({
    required String requestId,
    required int revision,
    required bool approve,
    String? notes,
  });
}
