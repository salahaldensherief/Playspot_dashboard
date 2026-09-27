import '../../domain/entities/tournament_entity.dart';

class TournamentModel extends TournamentEntity {
  const TournamentModel({
    required super.id,
    super.loungeId,
    super.loungeName,
    super.cityId,
    super.visibilityScope = 'all',
    super.visibilityRadiusKm,
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

    final titleVal = json['title_ar'] as String? ??
        json['title_en'] as String? ??
        json['title'] as String? ??
        '';
    final gameTitleVal = json['game_name'] as String? ?? json['game_title'] as String?;
    final treeSizeVal = json['bracket_size'] as int? ?? json['tree_size'] as int? ?? 8;
    final maxPlayersVal = json['max_participants'] as int? ?? json['max_players'] as int? ?? treeSizeVal;

    final startDateVal = json['tournament_starts_at'] != null
        ? DateTime.tryParse(json['tournament_starts_at'].toString())
        : (json['start_date'] != null
            ? DateTime.tryParse(json['start_date'].toString())
            : null);

    final regDeadlineVal = json['registration_closes_at'] != null
        ? DateTime.tryParse(json['registration_closes_at'].toString())
        : (json['registration_deadline'] != null
            ? DateTime.tryParse(json['registration_deadline'].toString())
            : null);

    final scopeVal = (json['visibility_scope'] as String?)?.toLowerCase() ?? 'all';
    final radiusVal = scopeVal == 'radius'
        ? (json['visibility_radius_km'] as num?)?.toDouble()
        : null;

    return TournamentModel(
      id: json['id'] as String? ?? '',
      loungeId: json['lounge_id'] as String?,
      loungeName: loungeNameVal ?? json['lounge_name'] as String?,
      cityId: json['city_id'] as String?,
      visibilityScope: scopeVal,
      visibilityRadiusKm: radiusVal,
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
      endDate: regDeadlineVal ?? (startDateVal ?? DateTime.now()),
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
      tournamentStartsAt: startDateVal,
      minPlayers: json['min_players'] as int? ?? 4,
      maxPlayers: maxPlayersVal,
      rules: json['description_ar'] as String? ?? json['rules'] as String?,
      registeredCount: json['registered_count'] as int? ??
          (json['tournament_participants'] is List ? (json['tournament_participants'] as List).length : 0),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  static bool _isValidUuid(String? str) {
    if (str == null || str.trim().isEmpty) return false;
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(str.trim());
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && _isValidUuid(id)) 'id': id,
      if (loungeId != null && _isValidUuid(loungeId)) 'lounge_id': loungeId,
      if (cityId != null && _isValidUuid(cityId)) 'city_id': cityId,
      'visibility_scope': visibilityScope,
      'visibility_radius_km': visibilityScope == 'radius' ? visibilityRadiusKm : null,
      'title_ar': (titleAr != null && titleAr!.isNotEmpty) ? titleAr : title,
      'title_en': (titleEn != null && titleEn!.isNotEmpty) ? titleEn : title,
      if (descriptionAr != null && descriptionAr!.isNotEmpty)
        'description_ar': descriptionAr
      else if (rules != null && rules!.isNotEmpty)
        'description_ar': rules,
      if (descriptionEn != null && descriptionEn!.isNotEmpty)
        'description_en': descriptionEn
      else if (rules != null && rules!.isNotEmpty)
        'description_en': rules,
      'game_name': gameTitle,
      'bracket_size': treeSize,
      'max_participants': maxPlayers,
      'entry_fee': entryFee,
      'registration_opens_at': (registrationOpensAt ?? startDate).toUtc().toIso8601String(),
      'registration_closes_at': (registrationClosesAt ?? registrationDeadline).toUtc().toIso8601String(),
      'payment_deadline_minutes': paymentDeadlineMinutes,
      if (checkInOpensAt != null)
        'check_in_opens_at': checkInOpensAt!.toUtc().toIso8601String(),
      if (checkInClosesAt != null)
        'check_in_closes_at': checkInClosesAt!.toUtc().toIso8601String(),
      'tournament_starts_at': (tournamentStartsAt ?? startDate).toUtc().toIso8601String(),
      'status': status.toDbString(),
      if (bannerUrl != null && bannerUrl!.isNotEmpty)
        'banner_url': bannerUrl,
    };
  }

  factory TournamentModel.fromEntity(TournamentEntity entity) {
    return TournamentModel(
      id: entity.id,
      loungeId: entity.loungeId,
      loungeName: entity.loungeName,
      cityId: entity.cityId,
      visibilityScope: entity.visibilityScope,
      visibilityRadiusKm: entity.visibilityRadiusKm,
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
