/// Parse a user-entered cash amount into cents without floating-point rounding.
int? parseOfflineCashMinor(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  var value = input.trim().replaceAll('٫', '.');
  for (var digit = 0; digit < 10; digit++) {
    value = value
        .replaceAll(arabic[digit], '$digit')
        .replaceAll(persian[digit], '$digit');
  }
  if (!RegExp(r'^\d{1,12}(?:[.]\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  final minor =
      int.parse(parts[0]) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return minor > 0 ? minor : null;
}
