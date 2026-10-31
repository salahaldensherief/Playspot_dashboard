import 'cashier_command_codec.dart';
import 'cashier_session_receipt_validator.dart';

class CashierReceiptValidator {
  static const _invalid = FormatException(
    'offline_cashier.invalid_sync_response',
  );
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static void validate(
    Map<String, dynamic> operation,
    Map<String, dynamic> response,
  ) {
    if (response['operation_id'] != operation['id'] ||
        response['sequence'] != operation['sequence'] ||
        response['lounge_id'] != operation['lounge_id'] ||
        !['applied', 'replayed', 'conflict'].contains(response['status'])) {
      throw _invalid;
    }
    if (response['status'] == 'conflict') {
      if (response['code'] is! String || (response['code'] as String).isEmpty) {
        throw _invalid;
      }
      return;
    }
    final receipt = _receipt(operation, response);
    if (receipt['booking_id'] != operation['booking_id'] ||
        receipt['lounge_id'] != operation['lounge_id']) {
      throw _invalid;
    }
    _validateBalance(receipt);
    switch (operation['kind']) {
      case 'collectCash':
        _validateCash(operation, receipt);
      case 'addItems':
        _validateOrder(operation, receipt);
      case 'reserve':
      case 'start':
      case 'close':
        CashierSessionReceiptValidator.validate(operation, receipt);
      default:
        throw _invalid;
    }
  }

  static Map _receipt(Map operation, Map response) {
    final key = switch (operation['kind']) {
      'collectCash' => 'financial_receipt',
      'addItems' => 'order_receipt',
      'reserve' || 'start' || 'close' => 'session_receipt',
      _ => throw _invalid,
    };
    final receipt = response[key];
    if (receipt is! Map) throw _invalid;
    return receipt;
  }

  static void _validateBalance(Map receipt) {
    final paid = _minor(receipt['paid_minor']);
    final due = _minor(receipt['due_minor']);
    _minor(paid + due);
    final status = due == 0
        ? 'paid'
        : paid > 0
        ? 'partial'
        : 'unpaid';
    if (receipt['payment_status'] != status) throw _invalid;
  }

  static void _validateCash(Map operation, Map receipt) {
    final payload = operation['payload'];
    final collected = _minor(receipt['collected_minor']);
    if (payload is! Map ||
        collected <= 0 ||
        collected != _minor(payload['amount_minor']) ||
        collected > _minor(receipt['paid_minor']) ||
        receipt['shift_id'] != operation['shift_id'] ||
        receipt['shift_payment_id'] is! String ||
        !_uuid.hasMatch(receipt['shift_payment_id'] as String)) {
      throw _invalid;
    }
  }

  static void _validateOrder(Map operation, Map receipt) {
    final items = receipt['items'];
    if (receipt['order_id'] != operation['id'] ||
        items is! List ||
        items.isEmpty ||
        items.length > 50 ||
        _minor(receipt['total_minor']) !=
            _minor(operation['quoted_total_minor']) ||
        _minor(receipt['paid_minor']) + _minor(receipt['due_minor']) !=
            _minor(receipt['total_minor'])) {
      throw _invalid;
    }
    final quotes = items.map(_quoteLine).toList();
    final orderTotal = quotes.fold<int>(
      0,
      (sum, quote) =>
          sum + (quote['unit_price_minor'] as int) * (quote['quantity'] as int),
    );
    if (_minor(receipt['order_total_minor']) != orderTotal ||
        CashierCommandCodec.canonical(quotes) !=
            CashierCommandCodec.canonical(operation['quoted_items'])) {
      throw _invalid;
    }
  }

  static Map<String, dynamic> _quoteLine(Object? item) {
    if (item is! Map || item['product_id'] != item['extra_id']) {
      throw _invalid;
    }
    final price = _priceMinor(item['unit_price']);
    final quantity = _minor(item['quantity']);
    if (quantity < 1 ||
        quantity > 100 ||
        _priceMinor(item['price']) != price ||
        _priceMinor(item['total_price']) != price * quantity) {
      throw _invalid;
    }
    return {
      'product_id': item['product_id'],
      'quantity': quantity,
      'unit_price_minor': price,
    };
  }

  static int _minor(Object? value) {
    if (value is! num ||
        !value.isFinite ||
        value < 0 ||
        value > 9007199254740991 ||
        value != value.round()) {
      throw _invalid;
    }
    return value.toInt();
  }

  static int _priceMinor(Object? value) {
    if (value is! num || !value.isFinite || value < 0) throw _invalid;
    final cents = value * 100;
    if (!cents.isFinite || cents > 9007199254740991) throw _invalid;
    if ((cents - cents.round()).abs() > 0.000001) throw _invalid;
    return _minor(cents.round());
  }

  static Map<String, dynamic> bookingProjection(Map operation, Map response) {
    final receipt = _receipt(operation, response);
    final paid = _minor(receipt['paid_minor']);
    final due = _minor(receipt['due_minor']);
    return {
      'booking_id': operation['booking_id'],
      'lounge_id': operation['lounge_id'],
      'last_sequence': operation['sequence'],
      'total_minor': paid + due,
      'paid_minor': paid,
      'due_minor': due,
      'payment_status': receipt['payment_status'],
      if (response['session_receipt'] is Map)
        ...CashierSessionReceiptValidator.projection(receipt),
    };
  }
}
