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

    test('round-trips non-console activity capabilities', () {
      final room = RoomModel.fromJson({
        'id': 'pool-1',
        'lounge_id': 'lounge-1',
        'name': 'Pool Table',
        'space_type_id': '00000000-0000-0000-0000-000000000123',
        'is_available': true,
        'status': 'available',
        'resource_type': 'table_sport',
        'requires_screen': false,
        'requires_controllers': false,
        'pricing_model': 'per_room_hour',
        'controllers_count': 0,
        'screen_size': '',
      });

      expect(room.resourceType, 'table_sport');
      expect(room.requiresScreen, isFalse);
      expect(room.requiresControllers, isFalse);
      expect(room.pricingModel, 'per_room_hour');

      final json = room.toJson();
      expect(json['resource_type'], 'table_sport');
      expect(json['requires_screen'], isFalse);
      expect(json['requires_controllers'], isFalse);
      expect(json['pricing_model'], 'per_room_hour');
      expect(json['controllers_count'], 0);
      expect(json['screen_size'], '');
    });
  });
}
