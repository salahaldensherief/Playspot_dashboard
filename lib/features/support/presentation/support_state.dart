import 'package:equatable/equatable.dart';
import '../domain/entities/app_settings_entity.dart';
import '../domain/entities/app_policy_entity.dart';
import '../domain/entities/faq_entity.dart';
import '../domain/entities/support_ticket_entity.dart';

enum SupportStatus { initial, loading, success, failure }

class SupportState extends Equatable {
  final SupportStatus status;
  final SupportStatus actionStatus;
  final AppSettingsEntity? settings;
  final List<AppPolicyEntity> policies;
  final List<FaqEntity> faqs;
  final List<SupportTicketEntity> tickets;
  final String activeTicketFilter;
  final String? errorMessage;
  final String? successMessage;

  const SupportState({
    this.status = SupportStatus.initial,
    this.actionStatus = SupportStatus.initial,
    this.settings,
    this.policies = const [],
    this.faqs = const [],
    this.tickets = const [],
    this.activeTicketFilter = 'all',
    this.errorMessage,
    this.successMessage,
  });

  SupportState copyWith({
    SupportStatus? status,
    SupportStatus? actionStatus,
    AppSettingsEntity? settings,
    List<AppPolicyEntity>? policies,
    List<FaqEntity>? faqs,
    List<SupportTicketEntity>? tickets,
    String? activeTicketFilter,
    String? errorMessage,
    String? successMessage,
  }) {
    return SupportState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      settings: settings ?? this.settings,
      policies: policies ?? this.policies,
      faqs: faqs ?? this.faqs,
      tickets: tickets ?? this.tickets,
      activeTicketFilter: activeTicketFilter ?? this.activeTicketFilter,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        settings,
        policies,
        faqs,
        tickets,
        activeTicketFilter,
        errorMessage,
        successMessage,
      ];
}
