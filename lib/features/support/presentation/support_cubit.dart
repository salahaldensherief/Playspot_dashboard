import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/entities/app_settings_entity.dart';
import '../domain/entities/app_policy_entity.dart';
import '../domain/entities/faq_entity.dart';
import '../domain/usecases/get_app_settings_usecase.dart';
import '../domain/usecases/update_app_settings_usecase.dart';
import '../domain/usecases/get_policies_usecase.dart';
import '../domain/usecases/update_policy_usecase.dart';
import '../domain/usecases/get_faqs_usecase.dart';
import '../domain/usecases/save_faq_usecase.dart';
import '../domain/usecases/delete_faq_usecase.dart';
import '../domain/usecases/get_support_tickets_usecase.dart';
import '../domain/usecases/create_support_ticket_usecase.dart';
import '../domain/usecases/update_ticket_status_usecase.dart';
import 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  final GetAppSettingsUseCase getAppSettingsUseCase;
  final UpdateAppSettingsUseCase updateAppSettingsUseCase;
  final GetPoliciesUseCase getPoliciesUseCase;
  final UpdatePolicyUseCase updatePolicyUseCase;
  final GetFaqsUseCase getFaqsUseCase;
  final SaveFaqUseCase saveFaqUseCase;
  final DeleteFaqUseCase deleteFaqUseCase;
  final GetSupportTicketsUseCase getSupportTicketsUseCase;
  final CreateSupportTicketUseCase createSupportTicketUseCase;
  final UpdateTicketStatusUseCase updateTicketStatusUseCase;

  SupportCubit({
    required this.getAppSettingsUseCase,
    required this.updateAppSettingsUseCase,
    required this.getPoliciesUseCase,
    required this.updatePolicyUseCase,
    required this.getFaqsUseCase,
    required this.saveFaqUseCase,
    required this.deleteFaqUseCase,
    required this.getSupportTicketsUseCase,
    required this.createSupportTicketUseCase,
    required this.updateTicketStatusUseCase,
  }) : super(const SupportState());

  Future<void> loadAppSettings() async {
    emit(state.copyWith(status: SupportStatus.loading));
    final result = await getAppSettingsUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        status: SupportStatus.failure,
        errorMessage: failure.message,
      )),
      (settings) => emit(state.copyWith(
        status: SupportStatus.success,
        settings: settings,
      )),
    );
  }

  Future<void> saveAppSettings(AppSettingsEntity newSettings) async {
    emit(state.copyWith(actionStatus: SupportStatus.loading));
    final result = await updateAppSettingsUseCase(newSettings);
    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: SupportStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        actionStatus: SupportStatus.success,
        settings: newSettings,
        successMessage: 'تم حفظ إعدادات التواصل والدفع بنجاح',
      )),
    );
  }

  Future<void> loadPolicies() async {
    emit(state.copyWith(status: SupportStatus.loading));
    final result = await getPoliciesUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        status: SupportStatus.failure,
        errorMessage: failure.message,
      )),
      (policies) => emit(state.copyWith(
        status: SupportStatus.success,
        policies: policies,
      )),
    );
  }

  Future<void> savePolicy(AppPolicyEntity policy) async {
    emit(state.copyWith(actionStatus: SupportStatus.loading));
    final result = await updatePolicyUseCase(policy);
    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: SupportStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedList = state.policies.map((p) => p.policyType == policy.policyType ? policy : p).toList();
        if (!updatedList.any((p) => p.policyType == policy.policyType)) {
          updatedList.add(policy);
        }
        emit(state.copyWith(
          actionStatus: SupportStatus.success,
          policies: updatedList,
          successMessage: 'تم حفظ ونشر السياسة بنجاح',
        ));
      },
    );
  }

  Future<void> loadFaqs() async {
    emit(state.copyWith(status: SupportStatus.loading));
    final result = await getFaqsUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        status: SupportStatus.failure,
        errorMessage: failure.message,
      )),
      (faqs) => emit(state.copyWith(
        status: SupportStatus.success,
        faqs: faqs,
      )),
    );
  }

  Future<void> saveFaq(FaqEntity faq) async {
    emit(state.copyWith(actionStatus: SupportStatus.loading));
    final result = await saveFaqUseCase(faq);
    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: SupportStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          actionStatus: SupportStatus.success,
          successMessage: 'تم حفظ السؤال الشائع بنجاح',
        ));
        loadFaqs();
      },
    );
  }

  Future<void> removeFaq(String id) async {
    emit(state.copyWith(actionStatus: SupportStatus.loading));
    final result = await deleteFaqUseCase(id);
    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: SupportStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          actionStatus: SupportStatus.success,
          successMessage: 'تم حذف السؤال الشائع',
        ));
        loadFaqs();
      },
    );
  }

  Future<void> loadTickets({String? statusFilter}) async {
    final filter = statusFilter ?? state.activeTicketFilter;
    emit(state.copyWith(status: SupportStatus.loading, activeTicketFilter: filter));
    final result = await getSupportTicketsUseCase(statusFilter: filter);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SupportStatus.failure,
        errorMessage: failure.message,
      )),
      (tickets) => emit(state.copyWith(
        status: SupportStatus.success,
        tickets: tickets,
      )),
    );
  }

  Future<void> createTicket({
    required String issueType,
    required String message,
  }) async {
    emit(state.copyWith(actionStatus: SupportStatus.loading));
    final result = await createSupportTicketUseCase(
      issueType: issueType,
      message: message,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: SupportStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          actionStatus: SupportStatus.success,
          successMessage: 'تم تقديم تذكرة الدعم بنجاح! سيقوم الدعم الفني بمراجعتها والتواصل معك.',
        ));
        loadTickets();
      },
    );
  }

  Future<void> changeTicketStatus({
    required String ticketId,
    required String status,
    String? adminNotes,
  }) async {
    emit(state.copyWith(actionStatus: SupportStatus.loading));
    final result = await updateTicketStatusUseCase(
      ticketId: ticketId,
      status: status,
      adminNotes: adminNotes,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: SupportStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          actionStatus: SupportStatus.success,
          successMessage: 'تم تحديث حالة التذكرة بنجاح',
        ));
        loadTickets();
      },
    );
  }
}
