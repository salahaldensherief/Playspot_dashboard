import '../../domain/entities/local_cashier_command.dart';
import 'local_cashier_booking_rules.dart';

class LocalCashierSaleRules {
  static void collectCash(
    Map<String, dynamic> state,
    LocalCashierCommand command,
  ) {
    final current = LocalCashierBookingRules.booking(state, command);
    final amount = command.payload['amount_minor'];
    final paid = current['paid_minor'] as int;
    final total = current['total_minor'] as int;
    if (amount is! int ||
        amount <= 0 ||
        amount > total - paid ||
        ['cancelled', 'rejected'].contains(current['status'])) {
      throw StateError('offline_cashier.invalid_payment');
    }
    current['paid_minor'] = paid + amount;
    current['payment_status'] = paid + amount == total ? 'paid' : 'partial';
    final shift = state['shift'] as Map;
    shift['collected_cash_minor'] =
        ((shift['collected_cash_minor'] as int?) ?? 0) + amount;
  }

  static void addItems(
    Map<String, dynamic> state,
    LocalCashierCommand command,
  ) {
    final current = LocalCashierBookingRules.booking(state, command);
    if (current['status'] != 'in_progress') {
      throw StateError('offline_cashier.invalid_transition');
    }
    final items = command.payload['items'];
    if (items is! List || items.isEmpty || items.length > 50) {
      throw StateError('offline_cashier.invalid_order');
    }
    final products = state['products'] as Map? ?? const {};
    final order = <Map<String, dynamic>>[];
    var total = 0;
    for (final item in items) {
      if (item is! Map) throw StateError('offline_cashier.invalid_order');
      final product = products[item['product_id']] as Map?;
      final quantity = item['quantity'];
      if (product == null ||
          product['is_active'] != true ||
          product['is_available'] != true ||
          product['track_stock'] is! bool ||
          quantity is! int ||
          quantity <= 0 ||
          quantity > 100 ||
          product['unit_price_minor'] is! int ||
          (product['unit_price_minor'] as int) < 0) {
        throw StateError('offline_cashier.invalid_order');
      }
      final stock = product['stock_quantity'];
      if (product['track_stock'] == true) {
        if (stock is! int || stock < quantity) {
          throw StateError('offline_cashier.insufficient_stock');
        }
        product['stock_quantity'] = stock - quantity;
      }
      final price = product['unit_price_minor'] as int;
      total += price * quantity;
      order.add({
        'product_id': item['product_id'],
        'quantity': quantity,
        'unit_price_minor': price,
      });
    }
    (current['items'] as List).add({
      'id': command.id,
      'items': order,
      'total_minor': total,
    });
    current['total_minor'] = (current['total_minor'] as int) + total;
    final paid = current['paid_minor'] as int;
    current['payment_status'] = paid == current['total_minor']
        ? 'paid'
        : paid > 0
        ? 'partial'
        : 'unpaid';
  }
}
