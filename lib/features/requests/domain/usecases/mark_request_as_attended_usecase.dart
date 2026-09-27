import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/client_requests_repository.dart';

class MarkRequestAttendedParams extends Equatable {
  final String requestId;
  final bool isCanteenOrder;

  const MarkRequestAttendedParams({
    required this.requestId,
    this.isCanteenOrder = false,
  });

  @override
  List<Object?> get props => [requestId, isCanteenOrder];
}

class MarkRequestAsAttendedUseCase implements UseCase<void, MarkRequestAttendedParams> {
  final ClientRequestsRepository repository;

  MarkRequestAsAttendedUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkRequestAttendedParams params) {
    return repository.markRequestAsAttended(
      params.requestId,
      isCanteenOrder: params.isCanteenOrder,
    );
  }
}
