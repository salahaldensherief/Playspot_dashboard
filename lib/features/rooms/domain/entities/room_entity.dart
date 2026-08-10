import 'package:equatable/equatable.dart';

enum RoomStatus { available, maintenance, occupied }

class RoomEntity extends Equatable {
  final String id;
  final String loungeId;
  final String nameAr;
  final String nameEn;
  final List<String> activityNames;
  final String? spaceType;
  final String? spaceTypeId;
  final int capacity;
  final double pricePerHour;
  final bool isAvailable;
  final List<String> images;
  final List<String> featuresAr;
  final List<String> featuresEn;
  final int controllersCount;
  final String screenSize;
  final RoomStatus status;

  const RoomEntity({
    required this.id,
    required this.loungeId,
    required this.nameAr,
    required this.nameEn,
    required this.activityNames,
    this.spaceType,
    this.spaceTypeId,
    required this.capacity,
    required this.pricePerHour,
    required this.isAvailable,
    required this.images,
    required this.featuresAr,
    required this.featuresEn,
    this.controllersCount = 2,
    this.screenSize = '43"',
    this.status = RoomStatus.available,
  });

  @override
  List<Object?> get props => [
        id,
        loungeId,
        nameAr,
        nameEn,
        activityNames,
        spaceType,
        spaceTypeId,
        capacity,
        pricePerHour,
        isAvailable,
        images,
        featuresAr,
        featuresEn,
        controllersCount,
        screenSize,
        status,
      ];
}
