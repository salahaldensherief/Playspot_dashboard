import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/cashier_conflict.dart';
import 'cashier_auth_request.dart';

class CashierConflictDataSource {
  final SupabaseClient client;
  const CashierConflictDataSource(this.client);

  Future<List<CashierConflict>> load(String actorId, String loungeId) async {
    final response = await CashierAuthRequest.run(
      client,
      actorId,
      () => client.rpc(
        'get_cashier_sync_conflicts',
        params: {'p_lounge_id': loungeId},
      ),
    );
    if (response is! List) {
      throw const FormatException('offline_conflicts.invalid_response');
    }
    return response
        .map((raw) {
          if (raw is! Map ||
              raw['sequence'] is! int ||
              (raw['sequence'] as int) < 1 ||
              raw['retry_pending'] is! bool) {
            throw const FormatException('offline_conflicts.invalid_response');
          }
          for (final key in [
            'operation_id',
            'booking_id',
            'actor_id',
            'kind',
            'code',
          ]) {
            final val = raw[key];
            if (val is! String || val.isEmpty) {
              throw const FormatException('offline_conflicts.invalid_response');
            }
          }
          return CashierConflict(
            operationId: raw['operation_id'] as String,
            bookingId: raw['booking_id'] as String,
            actorId: raw['actor_id'] as String,
            kind: raw['kind'] as String,
            code: raw['code'] as String,
            sequence: raw['sequence'] as int,
            retryPending: raw['retry_pending'] as bool,
          );
        })
        .toList(growable: false);
  }

  Future<void> approve({
    required String actorId,
    required String loungeId,
    required String operationId,
    required String reviewId,
    required String reason,
  }) async {
    final response = await CashierAuthRequest.run(
      client,
      actorId,
      () => client.rpc(
        'approve_cashier_conflict_retry',
        params: {
          'p_lounge_id': loungeId,
          'p_operation_id': operationId,
          'p_review_id': reviewId,
          'p_reason': reason,
        },
      ),
    );
    if (response is! Map ||
        response['lounge_id'] != loungeId ||
        response['operation_id'] != operationId ||
        response['review_id'] != reviewId ||
        response['status'] != 'approved') {
      throw const FormatException('offline_conflicts.invalid_response');
    }
  }
}
