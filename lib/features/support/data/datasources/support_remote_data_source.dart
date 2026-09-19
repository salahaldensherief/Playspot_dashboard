import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_settings_model.dart';
import '../models/app_policy_model.dart';
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
    final payload = settings.toJson();
    if (settings.id != null && settings.id!.isNotEmpty) {
      await supabaseClient.from('support_settings').upsert(payload, onConflict: 'id');
    } else {
      final existing = await supabaseClient.from('support_settings').select('id').limit(1).maybeSingle();
      if (existing != null) {
        payload['id'] = existing['id'];
        await supabaseClient.from('support_settings').update(payload).eq('id', existing['id']);
      } else {
        await supabaseClient.from('support_settings').insert(payload);
      }
    }
  }

  @override
  Future<List<AppPolicyModel>> getPolicies() async {
    final response = await supabaseClient
        .from('legal_policies')
        .select()
        .order('policy_type', ascending: true);

    return (response as List).map((e) => AppPolicyModel.fromJson(e)).toList();
  }

  @override
  Future<void> updatePolicy(AppPolicyModel policy) async {
    final payload = policy.toJson();
    await supabaseClient.from('legal_policies').upsert(payload, onConflict: 'id');
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
    final payload = faq.toJson();
    if (faq.id.isNotEmpty) {
      await supabaseClient.from('faqs').update(payload).eq('id', faq.id);
    } else {
      await supabaseClient.from('faqs').insert(payload);
    }
  }

  @override
  Future<void> deleteFaq(String id) async {
    await supabaseClient.from('faqs').delete().eq('id', id);
  }

  @override
  Future<List<SupportTicketModel>> getSupportTickets({String? statusFilter}) async {
    var query = supabaseClient.from('support_tickets').select();
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = query.eq('status', statusFilter);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((e) => SupportTicketModel.fromJson(e)).toList();
  }

  @override
  Future<void> createSupportTicket({
    required String issueType,
    required String message,
  }) async {
    try {
      await supabaseClient.rpc('create_support_ticket', params: {
        'issue_type': issueType,
        'message': message,
      });
    } on PostgrestException catch (_) {
      final user = supabaseClient.auth.currentUser;
      final userName = user?.userMetadata?['name'] as String? ?? user?.email ?? 'مالك صالة';
      final userPhone = user?.phone ?? user?.userMetadata?['phone'] as String? ?? '';
      await supabaseClient.from('support_tickets').insert({
        'user_id': user?.id,
        'user_name': userName,
        'user_phone': userPhone,
        'issue_type': issueType,
        'message': message,
        'status': 'new',
      });
    }
  }

  @override
  Future<void> updateTicketStatus({
    required String ticketId,
    required String status,
    String? adminNotes,
  }) async {
    final currentUserId = supabaseClient.auth.currentUser?.id;
    final Map<String, dynamic> payload = {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (adminNotes != null) {
      payload['admin_notes'] = adminNotes;
    }
    if (status == 'resolved') {
      payload['resolved_at'] = DateTime.now().toIso8601String();
      if (currentUserId != null) {
        payload['resolved_by'] = currentUserId;
      }
    }

    await supabaseClient.from('support_tickets').update(payload).eq('id', ticketId);
  }
}
