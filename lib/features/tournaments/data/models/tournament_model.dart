import '../../domain/entities/tournament_entity.dart';

class TournamentModel extends TournamentEntity {
  const TournamentModel({
    required super.id,
    super.loungeId,
    super.loungeName,
    required super.title,
    super.gameTitle,
    super.bannerUrl,
    required super.treeSize,
    required super.status,
    required super.entryFee,
    required super.prizePool,
    required super.startDate,
    required super.endDate,
    required super.registrationDeadline,
    required super.minPlayers,
    required super.maxPlayers,
    super.rules,
    super.registeredCount = 0,
    super.createdAt,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    String? loungeNameVal;
    if (json['lounges'] != null && json['lounges'] is Map) {
      loungeNameVal = json['lounges']['name'] as String?;
    }

    return TournamentModel(
      id: json['id'] as String? ?? '',
      loungeId: json['lounge_id'] as String?,
      loungeName: loungeNameVal ?? json['lounge_name'] as String?,
      title: json['title'] as String? ?? '',
      gameTitle: json['game_title'] as String?,
      bannerUrl: json['banner_url'] as String?,
      treeSize: json['tree_size'] as int? ?? 8,
      status: TournamentStatus.fromString(json['status'] as String?),
      entryFee: (json['entry_fee'] as num?)?.toDouble() ?? 0.0,
      prizePool: (json['prize_pool'] as num?)?.toDouble() ?? 0.0,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      registrationDeadline: json['registration_deadline'] != null
          ? DateTime.tryParse(json['registration_deadline'].toString()) ?? DateTime.now()
          : DateTime.now(),
      minPlayers: json['min_players'] as int? ?? 4,
      maxPlayers: json['max_players'] as int? ?? 32,
      rules: json['rules'] as String?,
      registeredCount: json['registered_count'] as int? ??
          (json['tournament_participants'] is List ? (json['tournament_participants'] as List).length : 0),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (loungeId != null) 'lounge_id': loungeId,
      'title': title,
      'game_title': gameTitle,
      'banner_url': bannerUrl,
      'tree_size': treeSize,
      'status': status.toDbString(),
      'entry_fee': entryFee,
      'prize_pool': prizePool,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'registration_deadline': registrationDeadline.toIso8601String(),
      'min_players': minPlayers,
      'max_players': maxPlayers,
      'rules': rules,
    };
  }

  factory TournamentModel.fromEntity(TournamentEntity entity) {
    return TournamentModel(
      id: entity.id,
      loungeId: entity.loungeId,
      loungeName: entity.loungeName,
      title: entity.title,
      gameTitle: entity.gameTitle,
      bannerUrl: entity.bannerUrl,
      treeSize: entity.treeSize,
      status: entity.status,
      entryFee: entity.entryFee,
      prizePool: entity.prizePool,
      startDate: entity.startDate,
      endDate: entity.endDate,
      registrationDeadline: entity.registrationDeadline,
      minPlayers: entity.minPlayers,
      maxPlayers: entity.maxPlayers,
      rules: entity.rules,
      registeredCount: entity.registeredCount,
      createdAt: entity.createdAt,
    );
  }
}
