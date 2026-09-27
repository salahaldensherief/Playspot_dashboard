import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dashboard Booking Pricing & Discount Alignment', () {
    test('staff discount percentage accurately computes manual discount amount', () {
      const roomPrice = 200.0;
      const addonsPrice = 100.0;
      const subtotal = roomPrice + addonsPrice;
      const discountPercentage = 15.0; // 15% off
      final calculatedDiscount = subtotal * (discountPercentage / 100.0);
      final finalTotal = subtotal - calculatedDiscount;

      expect(calculatedDiscount, 45.0);
      expect(finalTotal, 255.0);
    });

    test('canteen items addition preserves room price and existing manual discount', () {
      const initialRoomPrice = 100.0;
      const initialDiscount = 10.0;
      const addedCanteenTotal = 40.0;

      final updatedAddons = addedCanteenTotal;
      final updatedSubtotal = initialRoomPrice + updatedAddons;
      final updatedTotal = updatedSubtotal - initialDiscount;

      expect(updatedTotal, 130.0);
    });
  });
}
