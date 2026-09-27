import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/support_ticket_entity.dart';
import '../repositories/support_repository.dart';

class GetSupportTicketsUseCase {
  final SupportRepository repository;

  GetSupportTicketsUseCase(this.repository);

  Future<Either<Failure, List<SupportTicketEntity>>> call({String? statusFilter}) {
    return repository.getSupportTickets(statusFilter: statusFilter);
  }
}
