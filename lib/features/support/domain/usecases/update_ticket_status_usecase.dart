import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/support_repository.dart';

class UpdateTicketStatusUseCase {
  final SupportRepository repository;

  UpdateTicketStatusUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String ticketId,
    required String status,
    String? adminNotes,
  }) {
    return repository.updateTicketStatus(
      ticketId: ticketId,
      status: status,
      adminNotes: adminNotes,
    );
  }
}
