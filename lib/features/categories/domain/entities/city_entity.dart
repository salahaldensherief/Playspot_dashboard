import 'package:equatable/equatable.dart';

class CityEntity extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final bool isActive;

  const CityEntity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, nameAr, nameEn, isActive];

  CityEntity copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    bool? isActive,
  }) {
    return CityEntity(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      isActive: isActive ?? this.isActive,
    );
  }
}
