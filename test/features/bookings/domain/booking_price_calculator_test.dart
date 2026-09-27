import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking_price_calculator.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

RoomEntity _room({
  double single = 60.0,
  double multi = 80.0,
}) {
  return RoomEntity(
    id: 'r1',
    loungeId: 'l1',
    nameAr: 'غرفة',
    nameEn: 'Room',
    hourlyRateSingle: single,
    hourlyRateMulti: multi,
    isAvailable: true,
    images: const [],
    featuresAr: const [],
    featuresEn: const [],
  );
}

void main() {
  group('BookingPriceCalculator', () {
    test('returns all zeros when room is null', () {
      final result = BookingPriceCalculator.calculate(
        room: null,
        durationMinutes: 60,
        extras: const [],
        voucherDiscount: 10,
      );

      expect(result.pricePerHour, 0.0);
      expect(result.roomTotal, 0.0);
      expect(result.extrasTotal, 0.0);
      expect(result.subtotal, 0.0);
      expect(result.grandTotal, 0.0);
    });

    test('single mode uses hourlyRateSingle', () {
      final result = BookingPriceCalculator.calculate(
        room: _room(),
        durationMinutes: 90,
        extras: const [],
        voucherDiscount: 0,
        playMode: 'single',
      );

      expect(result.pricePerHour, 60.0);
      expect(result.roomTotal, 90.0);
      expect(result.grandTotal, 90.0);
    });

    test('multi mode uses hourlyRateMulti when set', () {
      final result = BookingPriceCalculator.calculate(
        room: _room(),
        durationMinutes: 60,
        extras: const [],
        voucherDiscount: 0,
        playMode: 'multi',
      );

      expect(result.pricePerHour, 80.0);
      expect(result.grandTotal, 80.0);
    });

    test('multi mode falls back to single rate when multi is not set', () {
      final result = BookingPriceCalculator.calculate(
        room: _room(multi: 0),
        durationMinutes: 60,
        extras: const [],
        voucherDiscount: 0,
        playMode: 'multi',
      );

      expect(result.pricePerHour, 60.0);
    });

    test('sums extras with quantity and tolerates string values', () {
      final result = BookingPriceCalculator.calculate(
        room: _room(),
        durationMinutes: 60,
        extras: [
          {'price': 10, 'quantity': 2},
          {'price': '5.5', 'quantity': '3'},
          {'quantity': null}, // missing price -> 0.0, missing qty -> 1
        ],
        voucherDiscount: 0,
      );

      expect(result.extrasTotal, closeTo(10 * 2 + 5.5 * 3, 0.001));
      expect(result.grandTotal, closeTo(60.0 + result.extrasTotal, 0.001));
    });

    test('voucher discount is clamped to subtotal', () {
      final result = BookingPriceCalculator.calculate(
        room: _room(),
        durationMinutes: 60,
        extras: const [],
        voucherDiscount: 500,
      );

      expect(result.voucherDiscount, 60.0);
      expect(result.grandTotal, 0.0);
    });

    test('negative voucher discount is clamped to zero', () {
      final result = BookingPriceCalculator.calculate(
        room: _room(),
        durationMinutes: 60,
        extras: const [],
        voucherDiscount: -20,
      );

      expect(result.voucherDiscount, 0.0);
      expect(result.grandTotal, 60.0);
    });

    test('grandTotal never goes negative with extras math edge cases', () {
      final result = BookingPriceCalculator.calculate(
        room: _room(single: 30),
        durationMinutes: 60,
        extras: const [
          {'price': 5, 'quantity': 1},
        ],
        voucherDiscount: 35,
      );

      expect(result.subtotal, 35.0);
      expect(result.grandTotal, 0.0);
    });
  });
}
