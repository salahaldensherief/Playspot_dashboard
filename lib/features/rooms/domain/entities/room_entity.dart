import 'package:equatable/equatable.dart';

enum RoomStatusEnum { available, maintenance, occupied }

class RoomEntity extends Equatable {
  final String id;
  final String loungeId;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final List<String> activityNames;
  final List<String> activityIds;
  final String? spaceType;
  final String? spaceTypeId;
  final int capacity;
  final double pricePerHourSingle;
  final double pricePerHourMulti;
  final double pricePerHour; // Kept for backward compatibility if needed
  final double extraControllerPrice;
  final bool isAvailable;
  final List<String> images;
  final List<String> featuresAr;
  final List<String> featuresEn;
  final int controllersCount;
  final String screenSize;
  final RoomStatusEnum status;

  bool get isOpenArea => spaceTypeId == 'open_area';

  const RoomEntity({
    required this.id,
    required this.loungeId,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr = '',
    this.descriptionEn = '',
    this.activityNames = const [],
    this.activityIds = const [],
    this.spaceType,
    this.spaceTypeId,
    required this.capacity,
    required this.pricePerHourSingle,
    required this.pricePerHourMulti,
    this.pricePerHour = 0.0,
    this.extraControllerPrice = 0.0,
    required this.isAvailable,
    required this.images,
    required this.featuresAr,
    required this.featuresEn,
    this.controllersCount = 2,
    this.screenSize = '43"',
    this.status = RoomStatusEnum.available,
  });

  @override
  List<Object?> get props => [
        id,
        loungeId,
        nameAr,
        nameEn,
        descriptionAr,
        descriptionEn,
        activityNames,
        activityIds,
        spaceType,
        spaceTypeId,
        capacity,
        pricePerHourSingle,
        pricePerHourMulti,
        pricePerHour,
        extraControllerPrice,
        isAvailable,
        images,
        featuresAr,
        featuresEn,
        controllersCount,
        screenSize,
        status,
      ];
}
