import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/client_request_entity.dart';
import '../../domain/repositories/client_requests_repository.dart';
import '../datasources/requests_remote_data_source.dart';

class ClientRequestsRepositoryImpl implements ClientRequestsRepository {
  final RequestsRemoteDataSource remoteDataSource;

  ClientRequestsRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<ClientRequestEntity>> watchClientRequests({required String loungeId}) {
    return remoteDataSource.watchClientRequests(loungeId: loungeId);
  }

  @override
  Future<Either<Failure, List<ClientRequestEntity>>> getClientRequests({required String loungeId}) async {
    try {
      final list = await remoteDataSource.getClientRequests(loungeId: loungeId);
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markRequestAsAttended(
    String requestId, {
    bool isCanteenOrder = false,
  }) async {
    try {
      await remoteDataSource.markRequestAsAttended(
        requestId,
        isCanteenOrder: isCanteenOrder,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
