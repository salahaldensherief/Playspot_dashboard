import 'package:equatable/equatable.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

class BookingPriceCalculation extends Equatable {
  final double pricePerHour;
  final double roomTotal;
  final double extrasTotal;
  final double voucherDiscount;
  final double subtotal;
  final double grandTotal;

  const BookingPriceCalculation({
    required this.pricePerHour,
    required this.roomTotal,
    required this.extrasTotal,
    required this.voucherDiscount,
    required this.subtotal,
    required this.grandTotal,
  });

  @override
  List<Object?> get props => [
        pricePerHour,
        roomTotal,
        extrasTotal,
        voucherDiscount,
        subtotal,
        grandTotal,
      ];
}

class BookingPriceCalculator {
  static BookingPriceCalculation calculate({
    required RoomEntity? room,
    required int durationMinutes,
    required List<Map<String, dynamic>> extras,
    required double voucherDiscount,
    String playMode = 'single',
  }) {
    if (room == null) {
      return const BookingPriceCalculation(
        pricePerHour: 0.0,
        roomTotal: 0.0,
        extrasTotal: 0.0,
        voucherDiscount: 0.0,
        subtotal: 0.0,
        grandTotal: 0.0,
      );
    }

    final double durationHours = durationMinutes / 60.0;

    // 1. Single source of truth for rate resolution
    final double pricePerHour = playMode == 'multi'
        ? (room.hourlyRateMulti > 0 ? room.hourlyRateMulti : room.pricePerHour)
        : (room.hourlyRateSingle > 0 ? room.hourlyRateSingle : room.pricePerHour);

    final double roomTotal = durationHours * pricePerHour;

    // 2. Extras calculation with safe type parsing and single field names ('quantity', 'price')
    double calculatedExtrasTotal = 0.0;
    for (final item in extras) {
      final int qty = int.tryParse(item['quantity']?.toString() ?? '') ?? 1;
      final double unitPrice = double.tryParse(item['price']?.toString() ?? '') ?? 0.0;
      calculatedExtrasTotal += unitPrice * qty;
    }

    // 3. Subtotal, voucher discount clamp, and non-negative grandTotal
    final double subtotal = roomTotal + calculatedExtrasTotal;
    final double clampedVoucherDiscount = voucherDiscount.clamp(0.0, subtotal);
    final double grandTotal = (subtotal - clampedVoucherDiscount).clamp(0.0, double.infinity);

    return BookingPriceCalculation(
      pricePerHour: pricePerHour,
      roomTotal: roomTotal,
      extrasTotal: calculatedExtrasTotal,
      voucherDiscount: clampedVoucherDiscount,
      subtotal: subtotal,
      grandTotal: grandTotal,
    );
  }
}
