import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/support_repository.dart';

class CreateSupportTicketUseCase {
  final SupportRepository repository;

  CreateSupportTicketUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String issueType,
    required String message,
  }) {
    return repository.createSupportTicket(
      issueType: issueType,
      message: message,
    );
  }
}
