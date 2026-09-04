import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/requests/data/models/client_request_model.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/client_request_entity.dart';

void main() {
  group('ClientRequestModel Factory Tests', () {
    test('fromNotificationJson parses call_staff correctly', () {
      final json = {
        'id': 'notif_101',
        'lounge_id': 'lounge_01',
        'type': 'call_staff',
        'title_ar': 'طلب مساعدة',
        'title_en': 'Staff Call',
        'body_ar': 'عميل بانتظار المساعدة في غرفة VIP 1',
        'body_en': 'Client requesting staff assistance in VIP 1',
        'is_read': false,
        'is_attended': false,
        'created_at': '2025-01-01T12:00:00.000Z',
        'metadata': {
          'booking_id': 'b_100',
          'room_id': 'r_200',
          'room_name': 'VIP 1',
        },
      };

      final model = ClientRequestModel.fromNotificationJson(json);

      expect(model.id, 'notif_101');
      expect(model.loungeId, 'lounge_01');
      expect(model.type, ClientRequestType.callStaff);
      expect(model.roomName, 'VIP 1');
      expect(model.isAttended, isFalse);
    });

    test('fromCanteenOrderJson parses canteen orders correctly', () {
      final json = {
        'id': 'order_55',
        'lounge_id': 'lounge_01',
        'booking_id': 'b_100',
        'room_name': 'Station 4',
        'user_name': 'Ahmed',
        'status': 'pending',
        'total_price': 150.0,
        'created_at': '2025-01-01T12:30:00.000Z',
        'items': [
          {'name': 'Pepsi', 'quantity': 2, 'price': 25.0},
          {'name': 'Chips', 'quantity': 1, 'price': 100.0},
        ],
      };

      final model = ClientRequestModel.fromCanteenOrderJson(json);

      expect(model.id, 'order_55');
      expect(model.type, ClientRequestType.canteenOrder);
      expect(model.isCanteenOrder, isTrue);
      expect(model.totalPrice, 150.0);
      expect(model.canteenItems.length, 2);
      expect(model.isAttended, isFalse);
    });

    test('fromBookingExtensionJson parses pending extensions correctly', () {
      final json = {
        'id': 'b_999',
        'lounge_id': 'lounge_01',
        'room_id': 'r_10',
        'room_name': 'PS5 Room 2',
        'user_name': 'Mohamed',
        'requested_minutes': 60,
        'duration_minutes': 120,
        'extension_status': 'pending',
        'updated_at': '2025-01-01T13:00:00.000Z',
      };

      final model = ClientRequestModel.fromBookingExtensionJson(json);

      expect(model.id, 'ext_b_999');
      expect(model.bookingId, 'b_999');
      expect(model.type, ClientRequestType.extendSession);
      expect(model.roomName, 'PS5 Room 2');
      expect(model.isAttended, isFalse);
      expect(model.metadata.items.first['requested_minutes'], 60);
      expect(model.metadata.items.first['current_duration'], 120);
    });
  });
}
