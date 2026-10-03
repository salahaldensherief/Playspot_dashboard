import 'package:supabase_flutter/supabase_flutter.dart';

class OwnerProvisioningException implements Exception {
  final String code;
  const OwnerProvisioningException(this.code);
  @override
  String toString() => code;
}

/// Auth credentials stay inside the authenticated Edge Function request. No
/// client-side profile promotion or SQL Auth account creation is permitted.
class LoungeOwnerProvisioner {
  final SupabaseClient client;
  const LoungeOwnerProvisioner(this.client);

  Future<Map<String, dynamic>> create({
    required String email,
    required String password,
    required String ownerName,
    required String loungeName,
    String? city,
    String? address,
    String? phone,
  }) async {
    try {
      final response = await client.functions.invoke(
        'create-lounge-owner',
        body: {
          'email': email,
          'password': password,
          'owner_name': ownerName,
          'lounge_name': loungeName,
          'city': city,
          'address': address,
          'phone': phone,
        },
      );
      final data = response.data;
      if (data is! Map ||
          data['success'] != true ||
          data['lounge_id'] is! String ||
          (data['lounge_id'] as String).isEmpty ||
          data['owner_id'] is! String ||
          (data['owner_id'] as String).isEmpty) {
        throw const OwnerProvisioningException('owner_account_create_failed');
      }
      return Map<String, dynamic>.from(data);
    } on FunctionException catch (error) {
      final details = error.details;
      throw OwnerProvisioningException(
        details is Map && details['error'] is String
            ? details['error'] as String
            : 'owner_account_create_failed',
      );
    }
  }
}
