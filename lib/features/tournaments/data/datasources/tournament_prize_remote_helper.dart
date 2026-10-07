import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tournament_prize_model.dart';
import '../models/tournament_prize_reward_model.dart';

class TournamentPrizeRemoteHelper {
  final SupabaseClient client;

  const TournamentPrizeRemoteHelper(this.client);

  Future<void> saveTournamentPrizes(
    String tournamentId,
    List<TournamentPrizeModel> prizes,
  ) async {
    final payload = prizes.map((prize) {
      return {
        'placement': prize.placement,
        'rewards': prize.rewards.map((reward) {
          final model = TournamentPrizeRewardModel.fromEntity(reward);
          final json = model.toJson();
          return {
            'reward_type': json['reward_type'],
            if (json['title_ar'] != null) 'title_ar': json['title_ar'],
            if (json['title_en'] != null) 'title_en': json['title_en'],
            if (json['description_ar'] != null)
              'description_ar': json['description_ar'],
            if (json['description_en'] != null)
              'description_en': json['description_en'],
            if (json['amount'] != null) 'amount': json['amount'],
            if (json['currency'] != null) 'currency': json['currency'],
            if (json['metadata'] != null) 'metadata': json['metadata'],
          };
        }).toList(),
      };
    }).toList();

    await client.rpc(
      'save_tournament_prizes',
      params: {
        'p_tournament_id': tournamentId,
        'p_prizes': payload,
      },
    );
  }
}
