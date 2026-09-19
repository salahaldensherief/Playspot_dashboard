import 'package:equatable/equatable.dart';

class AnnouncementEntity extends Equatable {
  final String id;
  final String targetAudience; // 'all', 'lounge_owners', 'specific_lounge'
  final String? targetLoungeId;
  final String? targetLoungeName;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final String type; // 'info', 'warning', 'update'
  final bool isActive;
  final DateTime createdAt;

  const AnnouncementEntity({
    required this.id,
    required this.targetAudience,
    this.targetLoungeId,
    this.targetLoungeName,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.type,
    this.isActive = true,
    required this.createdAt,
  });

  AnnouncementEntity copyWith({
    String? id,
    String? targetAudience,
    String? targetLoungeId,
    String? targetLoungeName,
    String? titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
    String? type,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AnnouncementEntity(
      id: id ?? this.id,
      targetAudience: targetAudience ?? this.targetAudience,
      targetLoungeId: targetLoungeId ?? this.targetLoungeId,
      targetLoungeName: targetLoungeName ?? this.targetLoungeName,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      bodyAr: bodyAr ?? this.bodyAr,
      bodyEn: bodyEn ?? this.bodyEn,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        targetAudience,
        targetLoungeId,
        targetLoungeName,
        titleAr,
        titleEn,
        bodyAr,
        bodyEn,
        type,
        isActive,
        createdAt,
      ];
}
