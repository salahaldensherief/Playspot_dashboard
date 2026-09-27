enum PaymentStatus { unpaid, paid, refunded }

enum PaymentMethod { cash, wallet, manualTransfer, card, online, other }

extension PaymentMethodX on PaymentMethod {
  String toDbString() {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.wallet:
        return 'wallet';
      case PaymentMethod.manualTransfer:
        return 'manual_transfer';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.online:
        return 'online';
      case PaymentMethod.other:
        return 'other';
    }
  }

  static PaymentMethod fromString(String? pm) {
    if (pm == null) return PaymentMethod.cash;
    final clean = pm.trim().toLowerCase();
    switch (clean) {
      case 'cash':
        return PaymentMethod.cash;
      case 'wallet':
        return PaymentMethod.wallet;
      case 'manual_transfer':
      case 'manual':
      case 'instapay':
      case 'vodafone_cash':
        return PaymentMethod.manualTransfer;
      case 'card':
      case 'credit_card':
      case 'visa':
        return PaymentMethod.card;
      case 'online':
      case 'fawry':
      case 'paymob':
        return PaymentMethod.online;
      default:
        return PaymentMethod.other;
    }
  }
}
