import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/rooms/data/models/room_model.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

void main() {
  group('RoomModel operational status serialization', () {
    RoomModel buildRoom(RoomStatusEnum status) {
      return RoomModel(
        id: 'room-1',
        loungeId: 'lounge-1',
        nameAr: 'غرفة',
        nameEn: 'Room',
        spaceTypeId: 'standard_room',
        isAvailable: status == RoomStatusEnum.available,
        images: const [],
        featuresAr: const [],
        featuresEn: const [],
        status: status,
      );
    }

    test('preserves occupied status', () {
      final json = buildRoom(RoomStatusEnum.occupied).toJson();

      expect(json['status'], 'occupied');
      expect(json['is_available'], isFalse);
    });

    test('preserves maintenance status', () {
      final json = buildRoom(RoomStatusEnum.maintenance).toJson();

      expect(json['status'], 'maintenance');
      expect(json['is_available'], isFalse);
    });

    test('preserves available status', () {
      final json = buildRoom(RoomStatusEnum.available).toJson();

      expect(json['status'], 'available');
      expect(json['is_available'], isTrue);
    });
  });
}
