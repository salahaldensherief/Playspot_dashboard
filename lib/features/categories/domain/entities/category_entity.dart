import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final String iconKey;

  const CategoryEntity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.iconKey,
  });

  @override
  List<Object?> get props => [id, nameAr, nameEn, iconKey];
}
