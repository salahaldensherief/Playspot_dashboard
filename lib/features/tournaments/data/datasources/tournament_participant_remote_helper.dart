import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/tournament_participant_model.dart';

class TournamentParticipantRemoteHelper {
  final SupabaseClient client;

  const TournamentParticipantRemoteHelper(this.client);

  Future<List<TournamentParticipantModel>> getParticipants(
    String tournamentId,
  ) async {
    try {
      final response = await client
          .from('tournament_participants')
          .select()
          .eq('tournament_id', tournamentId)
          .order('created_at', ascending: false);

      final rawList = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (rawList.isEmpty) return [];

      final userIds = rawList
          .map((json) => json['user_id']?.toString())
          .where((id) => id != null && id.trim().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> profilesMap = {};
      if (userIds.isNotEmpty) {
        try {
          final profilesResponse = await client
              .from('profiles')
              .select('id, full_name, phone, email, avatar_url')
              .inFilter('id', userIds);

          for (final p in profilesResponse as List) {
            final pMap = Map<String, dynamic>.from(p as Map);
            final pId = pMap['id']?.toString();
            if (pId != null) {
              profilesMap[pId] = pMap;
            }
          }
        } catch (e) {
          AppLogger.error('Profiles batch fetch failed for participants', e);
        }
      }

      final list = rawList.map((json) {
        final uId = json['user_id']?.toString();
        if (uId != null && profilesMap.containsKey(uId)) {
          json['profiles'] = profilesMap[uId];
        }
        return TournamentParticipantModel.fromJson(json);
      }).toList();

      final resultWithSignedUrls = await Future.wait(
        list.map((p) async {
          if (p.receiptPath != null && p.receiptPath!.isNotEmpty) {
            try {
              final signedUrl = await client.storage
                  .from('tournament-receipts')
                  .createSignedUrl(p.receiptPath!, 3600);
              return p.copyWithSignedUrl(signedUrl);
            } catch (storageErr) {
              AppLogger.error(
                'Failed to generate signed URL for receipt',
                storageErr,
              );
            }
          }
          return p;
        }),
      );

      return resultWithSignedUrls;
    } catch (e) {
      AppLogger.error('getParticipants error: $e', e);
      return [];
    }
  }

  Future<void> approvePayment(String participantId) async {
    await client.rpc(
      'review_tournament_payment_for_participant',
      params: {
        'p_participant_id': participantId,
        'p_approved': true,
        'p_reason': null,
      },
    );
  }

  Future<void> rejectPayment(String participantId, String reason) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw ArgumentError('Rejection reason is required');
    }

    await client.rpc(
      'review_tournament_payment_for_participant',
      params: {
        'p_participant_id': participantId,
        'p_approved': false,
        'p_reason': cleanReason,
      },
    );
  }

  Future<void> recordCashPayment(String participantId) async {
    try {
      final participantRes = await client
          .from('tournament_participants')
          .select(
            'tournament_id, registration_status, payment_status, tournaments(entry_fee)',
          )
          .eq('id', participantId)
          .maybeSingle();

      double amount = 0.0;
      if (participantRes != null) {
        final tData = participantRes['tournaments'];
        if (tData is Map) {
          amount = (tData['entry_fee'] as num?)?.toDouble() ?? 0.0;
        }
      }

      await client.rpc(
        'record_cash_tournament_payment',
        params: {
          'p_participant_id': participantId,
          'p_amount': amount,
          'p_reference_note': 'Cash payment recorded by admin',
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == 'P0001' &&
          (e.message == 'payment_not_allowed' ||
              e.message.contains('payment_not_allowed'))) {
        throw Exception(
          'Payment is not allowed: Participant registration has expired or payment deadline has passed.',
        );
      }
      rethrow;
    } catch (e) {
      AppLogger.error('recordCashPayment failed', e);
      rethrow;
    }
  }

  Future<void> checkInParticipant(String participantId) async {
    await client.rpc(
      'check_in_tournament_participant',
      params: {'p_participant_id': participantId},
    );
  }

  Future<void> withdrawParticipant(String participantId) async {
    await client.rpc(
      'withdraw_tournament_participant',
      params: {
        'p_participant_id': participantId,
        'p_reason': 'Admin withdrawal',
      },
    );
  }

  Future<void> promoteWaitlist(String tournamentId) async {
    await client.rpc(
      'promote_tournament_waitlist',
      params: {'p_tournament_id': tournamentId},
    );
  }


}
