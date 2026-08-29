import 'package:equatable/equatable.dart';

class PermissionItemEntity extends Equatable {
  final String key;
  final String nameAr;
  final String nameEn;
  final String category;
  final String descriptionAr;
  final String descriptionEn;
  final bool isEnabled;

  const PermissionItemEntity({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.isEnabled,
  });

  PermissionItemEntity copyWith({
    bool? isEnabled,
  }) {
    return PermissionItemEntity(
      key: key,
      nameAr: nameAr,
      nameEn: nameEn,
      category: category,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  List<Object?> get props => [key, nameAr, nameEn, category, descriptionAr, descriptionEn, isEnabled];
}
