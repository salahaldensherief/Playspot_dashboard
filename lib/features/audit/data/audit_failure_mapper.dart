import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/error/failures.dart';

Failure auditFailure(Object error) {
  final key = error is PostgrestException
      ? switch (error.code) {
          '42501' => 'audit_permission_denied',
          '28000' || 'PGRST301' => 'audit_session_expired',
          'PGRST202' || '42P01' => 'audit_service_unavailable',
          _ => 'audit_request_failed',
        }
      : 'audit_request_failed';
  return ServerFailure(key);
}
