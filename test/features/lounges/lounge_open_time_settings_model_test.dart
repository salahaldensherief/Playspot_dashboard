import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/lounges/data/models/lounge_payment_settings_model.dart';

void main() {
  test('reads persisted open-time policy using the live column names', () {
    final settings = LoungePaymentSettingsModel.fromJson({
      'id': 'lounge',
      'allow_open_time_sessions': true,
      'open_time_rounding_minutes': 30,
      'open_time_minimum_minutes': 90,
      'open_time_max_minutes': 840,
    });

    expect(settings.allowOpenTimeSessions, isTrue);
    expect(settings.openTimeRoundingMinutes, 30);
    expect(settings.openTimeMinMinutes, 90);
    expect(settings.openTimeMaxMinutes, 840);
    expect(settings.toJson()['open_time_minimum_minutes'], 90);
    expect(settings.toJson().containsKey('open_time_min_minutes'), isFalse);
  });

  test('missing policy does not silently enable open-time sessions', () {
    final settings = LoungePaymentSettingsModel.fromJson({'id': 'lounge'});
    expect(settings.allowOpenTimeSessions, isFalse);
    expect(settings.openTimeMinMinutes, 60);
  });
}
