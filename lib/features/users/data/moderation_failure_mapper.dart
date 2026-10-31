import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';

Failure moderationFailure(Object error) => ServerFailure(
  error is PostgrestException
      ? switch (error.code) {
          '42501' => 'moderation_permission_denied',
          '28000' || 'PGRST301' => 'moderation_session_expired',
          'PGRST202' || '42P01' => 'moderation_service_unavailable',
          _ => 'moderation_request_failed',
        }
      : 'moderation_request_failed',
);
