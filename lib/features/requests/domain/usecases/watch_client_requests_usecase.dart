import '../entities/client_request_entity.dart';
import '../repositories/client_requests_repository.dart';

class WatchClientRequestsUseCase {
  final ClientRequestsRepository repository;

  WatchClientRequestsUseCase(this.repository);

  Stream<List<ClientRequestEntity>> call({required String loungeId}) {
    return repository.watchClientRequests(loungeId: loungeId);
  }
}
