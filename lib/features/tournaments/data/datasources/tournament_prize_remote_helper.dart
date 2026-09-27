import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../models/tournament_prize_model.dart';

class TournamentPrizeRemoteHelper {
  final SupabaseClient client;

  const TournamentPrizeRemoteHelper(this.client);

  Future<void> saveTournamentPrizes(String tournamentId, List<TournamentPrizeModel> prizes) async {
    try {
      await client.from('tournament_prizes').delete().eq('tournament_id', tournamentId);
      for (final prizeModel in prizes) {
        final prizeData = {
          'tournament_id': tournamentId,
          'placement': prizeModel.placement,
        };
        final insertedPrize = await client
            .from('tournament_prizes')
            .insert(prizeData)
            .select('id')
            .single();

        final prizeId = insertedPrize['id']?.toString();
        if (prizeId != null && prizeModel.rewards.isNotEmpty) {
          final rewardsData = prizeModel.rewards.map((rewardModel) {
            return {
              'prize_id': prizeId,
              'type': rewardModel.type.toDbString(),
              if (rewardModel.title != null && rewardModel.title!.isNotEmpty) 'title': rewardModel.title,
              if (rewardModel.titleAr != null && rewardModel.titleAr!.isNotEmpty) 'title_ar': rewardModel.titleAr,
              if (rewardModel.titleEn != null && rewardModel.titleEn!.isNotEmpty) 'title_en': rewardModel.titleEn,
              if (rewardModel.description != null && rewardModel.description!.isNotEmpty) 'description': rewardModel.description,
              if (rewardModel.descriptionAr != null && rewardModel.descriptionAr!.isNotEmpty) 'description_ar': rewardModel.descriptionAr,
              if (rewardModel.descriptionEn != null && rewardModel.descriptionEn!.isNotEmpty) 'description_en': rewardModel.descriptionEn,
              if (rewardModel.value != null) 'value': rewardModel.value,
              if (rewardModel.currency != null && rewardModel.currency!.isNotEmpty) 'currency': rewardModel.currency,
              if (rewardModel.metadata != null) 'metadata': rewardModel.metadata,
              if (rewardModel.deliveryStatus != null) 'delivery_status': rewardModel.deliveryStatus,
            };
          }).toList();

          await client.from('tournament_prize_rewards').insert(rewardsData);
        }
      }
    } catch (e) {
      AppLogger.warning('saveTournamentPrizes error', e);
      rethrow;
    }
  }
}
