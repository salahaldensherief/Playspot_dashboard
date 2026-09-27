import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/repository_helper.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../../domain/entities/app_policy_entity.dart';
import '../../domain/entities/faq_entity.dart';
import '../../domain/entities/support_ticket_entity.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_remote_data_source.dart';
import '../models/app_settings_model.dart';
import '../models/app_policy_model.dart';
import '../models/faq_model.dart';

class SupportRepositoryImpl with RepositoryHelper implements SupportRepository {
  final SupportRemoteDataSource remoteDataSource;

  SupportRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, AppSettingsEntity>> getAppSettings() async {
    return callRepository(() => remoteDataSource.getAppSettings());
  }

  @override
  Future<Either<Failure, void>> updateAppSettings(AppSettingsEntity settings) async {
    return callRepository(() => remoteDataSource.updateAppSettings(
          AppSettingsModel(
            id: settings.id,
            whatsappPhone: settings.whatsappPhone,
            supportPhone: settings.supportPhone,
            supportEmail: settings.supportEmail,
            vodafoneCashNumber: settings.vodafoneCashNumber,
          ),
        ));
  }

  @override
  Future<Either<Failure, List<AppPolicyEntity>>> getPolicies() async {
    return callRepository(() => remoteDataSource.getPolicies());
  }

  @override
  Future<Either<Failure, void>> updatePolicy(AppPolicyEntity policy) async {
    return callRepository(() => remoteDataSource.updatePolicy(
          AppPolicyModel(
            id: policy.id,
            policyType: policy.policyType,
            titleAr: policy.titleAr,
            titleEn: policy.titleEn,
            contentAr: policy.contentAr,
            contentEn: policy.contentEn,
            isPublished: policy.isPublished,
          ),
        ));
  }

  @override
  Future<Either<Failure, List<FaqEntity>>> getFaqs() async {
    return callRepository(() => remoteDataSource.getFaqs());
  }

  @override
  Future<Either<Failure, void>> saveFaq(FaqEntity faq) async {
    return callRepository(() => remoteDataSource.saveFaq(
          FaqModel(
            id: faq.id,
            questionAr: faq.questionAr,
            answerAr: faq.answerAr,
            questionEn: faq.questionEn,
            answerEn: faq.answerEn,
            sortOrder: faq.sortOrder,
            isActive: faq.isActive,
          ),
        ));
  }

  @override
  Future<Either<Failure, void>> deleteFaq(String id) async {
    return callRepository(() => remoteDataSource.deleteFaq(id));
  }

  @override
  Future<Either<Failure, List<SupportTicketEntity>>> getSupportTickets({String? statusFilter}) async {
    return callRepository(() => remoteDataSource.getSupportTickets(statusFilter: statusFilter));
  }

  @override
  Future<Either<Failure, void>> createSupportTicket({
    required String issueType,
    required String message,
  }) async {
    return callRepository(() => remoteDataSource.createSupportTicket(
          issueType: issueType,
          message: message,
        ));
  }

  @override
  Future<Either<Failure, void>> updateTicketStatus({
    required String ticketId,
    required String status,
    String? adminNotes,
  }) async {
    return callRepository(() => remoteDataSource.updateTicketStatus(
          ticketId: ticketId,
          status: status,
          adminNotes: adminNotes,
        ));
  }
}
