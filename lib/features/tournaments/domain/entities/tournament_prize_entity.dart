import 'package:equatable/equatable.dart';
import 'tournament_prize_reward_entity.dart';

class TournamentPrizeEntity extends Equatable {
  final String id;
  final String tournamentId;
  final int placement; // 1 = 1st place, 2 = 2nd place, 3 = 3rd place, etc.
  final List<TournamentPrizeRewardEntity> rewards;
  final DateTime? createdAt;

  const TournamentPrizeEntity({
    required this.id,
    required this.tournamentId,
    required this.placement,
    this.rewards = const [],
    this.createdAt,
  });

  TournamentPrizeEntity copyWith({
    String? id,
    String? tournamentId,
    int? placement,
    List<TournamentPrizeRewardEntity>? rewards,
    DateTime? createdAt,
  }) {
    return TournamentPrizeEntity(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      placement: placement ?? this.placement,
      rewards: rewards ?? this.rewards,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        placement,
        rewards,
        createdAt,
      ];
}
