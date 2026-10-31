import 'dart:convert';

class CashierCommandCodec {
  static String canonical(Object? value) => jsonEncode(_sort(value));

  static Object? _sort(Object? value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: _sort(value[key])};
    }
    if (value is List) return value.map(_sort).toList();
    return value;
  }
}
