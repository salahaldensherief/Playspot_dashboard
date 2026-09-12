import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/paginated_result.dart';
import '../entities/client_request_entity.dart';

abstract class ClientRequestsRepository {
  /// Stream real-time notifications and client requests for a specific lounge.
  Stream<List<ClientRequestEntity>> watchClientRequests({required String loungeId});

  /// Fetch client requests once for a lounge.
  Future<Either<Failure, List<ClientRequestEntity>>> getClientRequests({required String loungeId});

  /// Fetch paginated active client requests for a lounge.
  Future<Either<Failure, PaginatedResult<ClientRequestEntity>>> getActiveLoungeRequestsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  });

  /// Mark a notification or canteen order as attended / read.
  Future<Either<Failure, void>> markRequestAsAttended(
    String requestId, {
    bool isCanteenOrder = false,
  });
}
