import 'package:equatable/equatable.dart';
import 'tournament_prize_entity.dart';

enum TournamentStatus {
  draft,
  published,
  registrationOpen,
  registrationClosed,
  checkInOpen,
  checkInClosed,
  drawCompleted,
  inProgress,
  completed,
  cancelled;

  static TournamentStatus fromString(String? value) {
    switch (value) {
      case 'published':
        return TournamentStatus.published;
      case 'registration_open':
        return TournamentStatus.registrationOpen;
      case 'registration_closed':
        return TournamentStatus.registrationClosed;
      case 'check_in_open':
        return TournamentStatus.checkInOpen;
      case 'check_in_closed':
        return TournamentStatus.checkInClosed;
      case 'draw_completed':
        return TournamentStatus.drawCompleted;
      case 'in_progress':
        return TournamentStatus.inProgress;
      case 'completed':
        return TournamentStatus.completed;
      case 'cancelled':
        return TournamentStatus.cancelled;
      case 'draft':
      default:
        return TournamentStatus.draft;
    }
  }

  String toDbString() {
    switch (this) {
      case TournamentStatus.published:
        return 'published';
      case TournamentStatus.registrationOpen:
        return 'registration_open';
      case TournamentStatus.registrationClosed:
        return 'registration_closed';
      case TournamentStatus.checkInOpen:
        return 'check_in_open';
      case TournamentStatus.checkInClosed:
        return 'check_in_closed';
      case TournamentStatus.drawCompleted:
        return 'draw_completed';
      case TournamentStatus.inProgress:
        return 'in_progress';
      case TournamentStatus.completed:
        return 'completed';
      case TournamentStatus.cancelled:
        return 'cancelled';
      case TournamentStatus.draft:
        return 'draft';
    }
  }
}

class TournamentEntity extends Equatable {
  final String id;
  final String? loungeId;
  final String? loungeName;
  final String? cityId;
  final String visibilityScope; // 'all' | 'city' | 'radius'
  final double? visibilityRadiusKm;
  final String title;
  final String? titleAr;
  final String? titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? gameTitle;
  final String? bannerUrl;
  final int treeSize; // 8, 16, 32
  final TournamentStatus status;
  final double entryFee;
  final double prizePool;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationDeadline;
  final DateTime? registrationOpensAt;
  final DateTime? registrationClosesAt;
  final int paymentDeadlineMinutes;
  final DateTime? checkInOpensAt;
  final DateTime? checkInClosesAt;
  final DateTime? tournamentStartsAt;
  final int minPlayers;
  final int maxPlayers;
  final String? rules;
  final int registeredCount;
  final List<TournamentPrizeEntity> prizes;
  final DateTime? createdAt;

  const TournamentEntity({
    required this.id,
    this.loungeId,
    this.loungeName,
    this.cityId,
    this.visibilityScope = 'all',
    this.visibilityRadiusKm,
    required this.title,
    this.titleAr,
    this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.gameTitle,
    this.bannerUrl,
    required this.treeSize,
    required this.status,
    required this.entryFee,
    required this.prizePool,
    required this.startDate,
    required this.endDate,
    required this.registrationDeadline,
    this.registrationOpensAt,
    this.registrationClosesAt,
    this.paymentDeadlineMinutes = 30,
    this.checkInOpensAt,
    this.checkInClosesAt,
    this.tournamentStartsAt,
    required this.minPlayers,
    required this.maxPlayers,
    this.rules,
    this.registeredCount = 0,
    this.prizes = const [],
    this.createdAt,
  });

  bool get isDraft => status == TournamentStatus.draft;
  bool get isPublished => status == TournamentStatus.published;
  bool get isInProgress => status == TournamentStatus.inProgress;
  bool get isCompleted => status == TournamentStatus.completed;
  bool get isCancelled => status == TournamentStatus.cancelled;

  bool get canDeleteDraft => isDraft && registeredCount == 0;
  bool get canDrawBracket => (isPublished || isDraft || status == TournamentStatus.registrationClosed || status == TournamentStatus.checkInClosed) && registeredCount >= minPlayers;

  TournamentEntity copyWith({
    String? id,
    String? loungeId,
    String? loungeName,
    String? cityId,
    String? visibilityScope,
    double? visibilityRadiusKm,
    String? title,
    String? titleAr,
    String? titleEn,
    String? descriptionAr,
    String? descriptionEn,
    String? gameTitle,
    String? bannerUrl,
    int? treeSize,
    TournamentStatus? status,
    double? entryFee,
    double? prizePool,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    DateTime? registrationOpensAt,
    DateTime? registrationClosesAt,
    int? paymentDeadlineMinutes,
    DateTime? checkInOpensAt,
    DateTime? checkInClosesAt,
    DateTime? tournamentStartsAt,
    int? minPlayers,
    int? maxPlayers,
    String? rules,
    int? registeredCount,
    List<TournamentPrizeEntity>? prizes,
    DateTime? createdAt,
  }) {
    return TournamentEntity(
      id: id ?? this.id,
      loungeId: loungeId ?? this.loungeId,
      loungeName: loungeName ?? this.loungeName,
      cityId: cityId ?? this.cityId,
      visibilityScope: visibilityScope ?? this.visibilityScope,
      visibilityRadiusKm: visibilityRadiusKm ?? this.visibilityRadiusKm,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      gameTitle: gameTitle ?? this.gameTitle,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      treeSize: treeSize ?? this.treeSize,
      status: status ?? this.status,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      registrationOpensAt: registrationOpensAt ?? this.registrationOpensAt,
      registrationClosesAt: registrationClosesAt ?? this.registrationClosesAt,
      paymentDeadlineMinutes: paymentDeadlineMinutes ?? this.paymentDeadlineMinutes,
      checkInOpensAt: checkInOpensAt ?? this.checkInOpensAt,
      checkInClosesAt: checkInClosesAt ?? this.checkInClosesAt,
      tournamentStartsAt: tournamentStartsAt ?? this.tournamentStartsAt,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      rules: rules ?? this.rules,
      registeredCount: registeredCount ?? this.registeredCount,
      prizes: prizes ?? this.prizes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        loungeId,
        loungeName,
        cityId,
        visibilityScope,
        visibilityRadiusKm,
        title,
        titleAr,
        titleEn,
        descriptionAr,
        descriptionEn,
        gameTitle,
        bannerUrl,
        treeSize,
        status,
        entryFee,
        prizePool,
        startDate,
        endDate,
        registrationDeadline,
        registrationOpensAt,
        registrationClosesAt,
        paymentDeadlineMinutes,
        checkInOpensAt,
        checkInClosesAt,
        tournamentStartsAt,
        minPlayers,
        maxPlayers,
        rules,
        registeredCount,
        prizes,
        createdAt,
      ];
}
