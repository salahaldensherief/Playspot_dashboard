import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_policy_model.dart';
import '../models/app_settings_model.dart';
import '../models/faq_model.dart';
import '../models/support_ticket_model.dart';

abstract class SupportRemoteDataSource {
  Future<AppSettingsModel> getAppSettings();
  Future<void> updateAppSettings(AppSettingsModel settings);

  Future<List<AppPolicyModel>> getPolicies();
  Future<void> updatePolicy(AppPolicyModel policy);

  Future<List<FaqModel>> getFaqs();
  Future<void> saveFaq(FaqModel faq);
  Future<void> deleteFaq(String id);

  Future<List<SupportTicketModel>> getSupportTickets({String? statusFilter});
  Future<void> createSupportTicket({
    required String issueType,
    required String message,
  });
  Future<void> updateTicketStatus({
    required String ticketId,
    required String status,
    String? adminNotes,
  });
}

class SupportRemoteDataSourceImpl implements SupportRemoteDataSource {
  final SupabaseClient supabaseClient;

  SupportRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<AppSettingsModel> getAppSettings() async {
    final response = await supabaseClient
        .from('support_settings')
        .select()
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return const AppSettingsModel(
        whatsappPhone: '',
        supportPhone: '',
        supportEmail: '',
        vodafoneCashNumber: '',
      );
    }
    return AppSettingsModel.fromJson(response);
  }

  @override
  Future<void> updateAppSettings(AppSettingsModel settings) async {
    await supabaseClient.rpc(
      'admin_update_support_settings',
      params: {
        'p_whatsapp_phone': settings.whatsappPhone,
        'p_support_phone': settings.supportPhone,
        'p_support_email': settings.supportEmail,
        'p_vodafone_cash_number': settings.vodafoneCashNumber,
      },
    );
  }

  @override
  Future<List<AppPolicyModel>> getPolicies() async {
    final response = await supabaseClient
        .from('legal_policies')
        .select()
        .order('policy_key', ascending: true);

    return (response as List).map((e) => AppPolicyModel.fromJson(e)).toList();
  }

  @override
  Future<void> updatePolicy(AppPolicyModel policy) async {
    final policyKey = policy.policyType.trim().isNotEmpty
        ? policy.policyType.trim()
        : policy.id.trim();

    await supabaseClient.rpc(
      'admin_upsert_legal_policy',
      params: {
        'p_policy_key': policyKey,
        'p_title_ar': policy.titleAr,
        'p_title_en': policy.titleEn,
        'p_content_ar': policy.contentAr,
        'p_content_en': policy.contentEn,
        'p_is_published': policy.isPublished,
      },
    );
  }

  @override
  Future<List<FaqModel>> getFaqs() async {
    final response = await supabaseClient
        .from('faqs')
        .select()
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);

    return (response as List).map((e) => FaqModel.fromJson(e)).toList();
  }

  @override
  Future<void> saveFaq(FaqModel faq) async {
    await supabaseClient.rpc(
      'admin_save_faq',
      params: {
        'p_id': faq.id.isEmpty ? null : faq.id,
        'p_question_ar': faq.questionAr,
        'p_answer_ar': faq.answerAr,
        'p_question_en': faq.questionEn,
        'p_answer_en': faq.answerEn,
        'p_sort_order': faq.sortOrder,
        'p_is_active': faq.isActive,
      },
    );
  }

  @override
  Future<void> deleteFaq(String id) async {
    await supabaseClient.rpc(
      'admin_delete_faq',
      params: {'p_id': id},
    );
  }

  @override
  Future<List<SupportTicketModel>> getSupportTickets({
    String? statusFilter,
  }) async {
    var query = supabaseClient.from('support_tickets').select();
    if (statusFilter != null &&
        statusFilter.isNotEmpty &&
        statusFilter != 'all') {
      query = query.eq('status', statusFilter);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((e) => SupportTicketModel.fromJson(e))
        .toList();
  }

  @override
  Future<void> createSupportTicket({
    required String issueType,
    required String message,
  }) async {
    await supabaseClient.rpc(
      'create_support_ticket',
      params: {'p_issue_type': issueType, 'p_message': message},
    );
  }

  @override
  Future<void> updateTicketStatus({
    required String ticketId,
    required String status,
    String? adminNotes,
  }) async {
    await supabaseClient.rpc(
      'admin_update_support_ticket',
      params: {
        'p_ticket_id': ticketId,
        'p_status': status,
        'p_admin_notes': adminNotes,
      },
    );
  }
}
