import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_settings_entity.dart';
import '../entities/app_policy_entity.dart';
import '../entities/faq_entity.dart';
import '../entities/support_ticket_entity.dart';

abstract class SupportRepository {
  Future<Either<Failure, AppSettingsEntity>> getAppSettings();
  Future<Either<Failure, void>> updateAppSettings(AppSettingsEntity settings);

  Future<Either<Failure, List<AppPolicyEntity>>> getPolicies();
  Future<Either<Failure, void>> updatePolicy(AppPolicyEntity policy);

  Future<Either<Failure, List<FaqEntity>>> getFaqs();
  Future<Either<Failure, void>> saveFaq(FaqEntity faq);
  Future<Either<Failure, void>> deleteFaq(String id);

  Future<Either<Failure, List<SupportTicketEntity>>> getSupportTickets({String? statusFilter});
  Future<Either<Failure, void>> createSupportTicket({
    required String issueType,
    required String message,
  });
  Future<Either<Failure, void>> updateTicketStatus({
    required String ticketId,
    required String status,
    String? adminNotes,
  });
}
