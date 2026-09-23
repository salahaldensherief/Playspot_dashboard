import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import 'package:play_spot_dashboard/features/requests/data/models/client_request_model.dart';

abstract class RequestsRemoteDataSource {
  Stream<List<ClientRequestModel>> watchClientRequests({required String loungeId});
  Future<List<ClientRequestModel>> getClientRequests({required String loungeId});
  Future<PaginatedResult<ClientRequestModel>> getActiveLoungeRequestsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  });
  Future<void> markRequestAsAttended(String id, {bool isCanteenOrder = false});
}
