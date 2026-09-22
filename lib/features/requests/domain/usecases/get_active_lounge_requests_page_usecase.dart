import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../../../../core/utils/paginated_result.dart';
import '../entities/client_request_entity.dart';
import '../repositories/client_requests_repository.dart';

class GetActiveLoungeRequestsPageParams extends Equatable {
  final String loungeId;
  final int page;
  final int pageSize;

  const GetActiveLoungeRequestsPageParams({
    required this.loungeId,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [loungeId, page, pageSize];
}

class GetActiveLoungeRequestsPageUseCase
    implements UseCase<PaginatedResult<ClientRequestEntity>, GetActiveLoungeRequestsPageParams> {
  final ClientRequestsRepository repository;

  GetActiveLoungeRequestsPageUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<ClientRequestEntity>>> call(
      GetActiveLoungeRequestsPageParams params) {
    return repository.getActiveLoungeRequestsPage(
      loungeId: params.loungeId,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
