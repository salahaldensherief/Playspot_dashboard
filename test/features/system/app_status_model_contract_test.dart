import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/system/data/models/app_status_model.dart';

void main() {
  // Regression coverage for canonical platform version columns.
  test('maps canonical app_status columns', () {
    final model = AppStatusModel.fromJson({
      'id': 1,
      'maintenance_mode': true,
      'maintenance_message_ar': 'صيانة',
      'maintenance_message_en': 'Maintenance',
      'maintenance_until': '2026-09-28T01:00:00Z',
      'min_supported_version_android': '2.3.0',
      'min_supported_version_ios': '2.2.0',
      'latest_version_android': '2.5.0',
      'latest_version_ios': '2.4.0',
      'store_url_android': 'https://example.com/android',
      'store_url_ios': 'https://example.com/ios',
      'update_message_ar': 'حدّث التطبيق',
      'update_message_en': 'Update the app',
    });

    expect(model.isMaintenanceMode, isTrue);
    expect(model.expectedEndTime, isNotNull);
    expect(model.minAndroidVersion, '2.3.0');
    expect(model.minIosVersion, '2.2.0');
    expect(model.latestAndroidVersion, '2.5.0');
    expect(model.latestIosVersion, '2.4.0');
  });
}
