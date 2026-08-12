import 'package:dartz/dartz.dart';
import 'dart:typed_data';
import '../../../../core/error/failures.dart';
import '../../domain/entities/kyc_request.dart';
import '../../domain/repositories/kyc_repository.dart';
import '../datasources/kyc_remote_data_source.dart';

class KycRepositoryImpl implements KycRepository {
  final KycRemoteDataSource _remoteDataSource;

  KycRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, void>> submitKyc({
    required String userId,
    required Uint8List idCardBytes,
    required String idCardName,
    Uint8List? businessDocBytes,
    String? businessDocName,
  }) async {
    try {
      await _remoteDataSource.submitKyc(
        userId: userId,
        idCardBytes: idCardBytes,
        idCardName: idCardName,
        businessDocBytes: businessDocBytes,
        businessDocName: businessDocName,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<KycRequest>>> getPendingReviews() async {
    try {
      final results = await _remoteDataSource.getPendingReviews();
      return Right(results.map((e) => KycRequest.fromJson(e)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reviewKyc({
    required String userId,
    required bool approve,
    String? notes,
  }) async {
    try {
      await _remoteDataSource.reviewKyc(
        userId: userId,
        approve: approve,
        notes: notes,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
