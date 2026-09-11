import '../../domain/entities/tournament_entity.dart';

class TournamentModel extends TournamentEntity {
  const TournamentModel({
    required super.id,
    super.loungeId,
    super.loungeName,
    super.cityId,
    required super.title,
    super.titleAr,
    super.titleEn,
    super.descriptionAr,
    super.descriptionEn,
    super.gameTitle,
    super.bannerUrl,
    required super.treeSize,
    required super.status,
    required super.entryFee,
    required super.prizePool,
    required super.startDate,
    required super.endDate,
    required super.registrationDeadline,
    super.registrationOpensAt,
    super.registrationClosesAt,
    super.paymentDeadlineMinutes,
    super.checkInOpensAt,
    super.checkInClosesAt,
    super.tournamentStartsAt,
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

    final titleVal = json['title'] as String? ??
        json['title_ar'] as String? ??
        json['title_en'] as String? ??
        '';
    final gameTitleVal = json['game_title'] as String? ?? json['game_name'] as String?;
    final treeSizeVal = json['tree_size'] as int? ?? json['bracket_size'] as int? ?? 8;
    final maxPlayersVal = json['max_players'] as int? ?? json['max_participants'] as int? ?? treeSizeVal;

    final startDateVal = json['start_date'] != null
        ? DateTime.tryParse(json['start_date'].toString())
        : (json['tournament_starts_at'] != null
            ? DateTime.tryParse(json['tournament_starts_at'].toString())
            : null);

    final regDeadlineVal = json['registration_deadline'] != null
        ? DateTime.tryParse(json['registration_deadline'].toString())
        : (json['registration_closes_at'] != null
            ? DateTime.tryParse(json['registration_closes_at'].toString())
            : null);

    return TournamentModel(
      id: json['id'] as String? ?? '',
      loungeId: json['lounge_id'] as String?,
      loungeName: loungeNameVal ?? json['lounge_name'] as String?,
      cityId: json['city_id'] as String?,
      title: titleVal,
      titleAr: json['title_ar'] as String?,
      titleEn: json['title_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      gameTitle: gameTitleVal,
      bannerUrl: json['banner_url'] as String?,
      treeSize: treeSizeVal,
      status: TournamentStatus.fromString(json['status'] as String?),
      entryFee: (json['entry_fee'] as num?)?.toDouble() ?? 0.0,
      prizePool: (json['prize_pool'] as num?)?.toDouble() ?? 0.0,
      startDate: startDateVal ?? DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      registrationDeadline: regDeadlineVal ?? DateTime.now(),
      registrationOpensAt: json['registration_opens_at'] != null
          ? DateTime.tryParse(json['registration_opens_at'].toString())
          : null,
      registrationClosesAt: json['registration_closes_at'] != null
          ? DateTime.tryParse(json['registration_closes_at'].toString())
          : null,
      paymentDeadlineMinutes: json['payment_deadline_minutes'] as int? ?? 30,
      checkInOpensAt: json['check_in_opens_at'] != null
          ? DateTime.tryParse(json['check_in_opens_at'].toString())
          : null,
      checkInClosesAt: json['check_in_closes_at'] != null
          ? DateTime.tryParse(json['check_in_closes_at'].toString())
          : null,
      tournamentStartsAt: json['tournament_starts_at'] != null
          ? DateTime.tryParse(json['tournament_starts_at'].toString())
          : startDateVal,
      minPlayers: json['min_players'] as int? ?? 4,
      maxPlayers: maxPlayersVal,
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
      if (cityId != null) 'city_id': cityId,
      'title': title,
      if (titleAr != null) 'title_ar': titleAr,
      if (titleEn != null) 'title_en': titleEn,
      if (descriptionAr != null) 'description_ar': descriptionAr,
      if (descriptionEn != null) 'description_en': descriptionEn,
      'game_title': gameTitle,
      'game_name': gameTitle,
      'banner_url': bannerUrl,
      'tree_size': treeSize,
      'bracket_size': treeSize,
      'status': status.toDbString(),
      'entry_fee': entryFee,
      'prize_pool': prizePool,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'registration_deadline': registrationDeadline.toIso8601String(),
      if (registrationOpensAt != null) 'registration_opens_at': registrationOpensAt!.toIso8601String(),
      if (registrationClosesAt != null) 'registration_closes_at': registrationClosesAt!.toIso8601String(),
      'payment_deadline_minutes': paymentDeadlineMinutes,
      if (checkInOpensAt != null) 'check_in_opens_at': checkInOpensAt!.toIso8601String(),
      if (checkInClosesAt != null) 'check_in_closes_at': checkInClosesAt!.toIso8601String(),
      'tournament_starts_at': (tournamentStartsAt ?? startDate).toIso8601String(),
      'min_players': minPlayers,
      'max_players': maxPlayers,
      'max_participants': maxPlayers,
      'rules': rules,
    };
  }

  factory TournamentModel.fromEntity(TournamentEntity entity) {
    return TournamentModel(
      id: entity.id,
      loungeId: entity.loungeId,
      loungeName: entity.loungeName,
      cityId: entity.cityId,
      title: entity.title,
      titleAr: entity.titleAr,
      titleEn: entity.titleEn,
      descriptionAr: entity.descriptionAr,
      descriptionEn: entity.descriptionEn,
      gameTitle: entity.gameTitle,
      bannerUrl: entity.bannerUrl,
      treeSize: entity.treeSize,
      status: entity.status,
      entryFee: entity.entryFee,
      prizePool: entity.prizePool,
      startDate: entity.startDate,
      endDate: entity.endDate,
      registrationDeadline: entity.registrationDeadline,
      registrationOpensAt: entity.registrationOpensAt,
      registrationClosesAt: entity.registrationClosesAt,
      paymentDeadlineMinutes: entity.paymentDeadlineMinutes,
      checkInOpensAt: entity.checkInOpensAt,
      checkInClosesAt: entity.checkInClosesAt,
      tournamentStartsAt: entity.tournamentStartsAt,
      minPlayers: entity.minPlayers,
      maxPlayers: entity.maxPlayers,
      rules: entity.rules,
      registeredCount: entity.registeredCount,
      createdAt: entity.createdAt,
    );
  }
}
