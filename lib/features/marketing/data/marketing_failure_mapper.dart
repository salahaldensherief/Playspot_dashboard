import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';

Failure marketingFailure(Object error) => ServerFailure(
  error is PostgrestException
      ? switch (error.code) {
          'P0002' => 'promotion_not_found',
          '42501' => 'promotion_permission_denied',
          '28000' || 'PGRST301' => 'promotion_session_expired',
          '22023' => 'promotion_invalid_details',
          _ => 'promotion_operation_failed',
        }
      : 'promotion_operation_failed',
);
