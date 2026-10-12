import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/domain/services/booking_schedule.dart';

void main() {
  final date = DateTime(2030, 1, 10);
  test('invalid booking times cannot silently become midnight', () {
    for (final value in [
      'bad:time',
      '24:00',
      '14:60',
      '14:00:60',
      '',
      '14:00:NaN',
    ]) {
      expect(BookingSchedule.startAt(date, value), isNull);
    }
    expect(BookingSchedule.canStart(null, date), isFalse);
  });
  test(
    'seconds are retained and start readiness changes exactly at the allowed window',
    () {
      final start = BookingSchedule.startAt(date, '14:00:30');
      expect(start, DateTime(2030, 1, 10, 14, 0, 30));
      expect(
        BookingSchedule.canStart(start, DateTime(2030, 1, 10, 13, 45, 29)),
        isFalse,
      );
      expect(
        BookingSchedule.canStart(start, DateTime(2030, 1, 10, 13, 45, 30)),
        isTrue,
      );
    },
  );
  test('legacy timestamp times retain their actual instant', () {
    const timestamp = '2030-01-10T12:00:00Z';
    expect(
      BookingSchedule.startAt(date, timestamp),
      DateTime.parse(timestamp).toLocal(),
    );
  });
}
