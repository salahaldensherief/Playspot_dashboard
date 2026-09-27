import '../../domain/entities/tournament_prize_entity.dart';
import 'tournament_prize_reward_model.dart';

class TournamentPrizeModel extends TournamentPrizeEntity {
  const TournamentPrizeModel({
    required super.id,
    required super.tournamentId,
    required super.placement,
    super.rewards = const [],
    super.createdAt,
  });

  factory TournamentPrizeModel.fromJson(Map<String, dynamic> json) {
    List<TournamentPrizeRewardModel> rewardsList = [];
    if (json['tournament_prize_rewards'] != null && json['tournament_prize_rewards'] is List) {
      rewardsList = (json['tournament_prize_rewards'] as List)
          .map((r) => TournamentPrizeRewardModel.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    }

    return TournamentPrizeModel(
      id: json['id'] as String? ?? '',
      tournamentId: json['tournament_id'] as String? ?? '',
      placement: json['placement'] as int? ?? 1,
      rewards: rewardsList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && !id.startsWith('temp_')) 'id': id,
      if (tournamentId.isNotEmpty && !tournamentId.startsWith('temp_')) 'tournament_id': tournamentId,
      'placement': placement,
      'tournament_prize_rewards': rewards
          .map((r) => TournamentPrizeRewardModel.fromEntity(r).toJson())
          .toList(),
    };
  }

  factory TournamentPrizeModel.fromEntity(TournamentPrizeEntity entity) {
    return TournamentPrizeModel(
      id: entity.id,
      tournamentId: entity.tournamentId,
      placement: entity.placement,
      rewards: entity.rewards,
      createdAt: entity.createdAt,
    );
  }
}
