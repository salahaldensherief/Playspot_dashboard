import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/system/data/models/app_status_model.dart';

void main() {
  test('maps the live app_status schema into dashboard fields', () {
    final model = AppStatusModel.fromJson(const {
      'id': 1,
      'maintenance_mode': true,
      'maintenance_message': 'legacy',
      'maintenance_message_ar': 'صيانة',
      'maintenance_message_en': 'Maintenance',
      'maintenance_until': '2026-10-01T12:00:00Z',
      'min_supported_version_android': '2.1.0',
      'min_supported_version_ios': '2.2.0',
      'latest_version_android': '2.5.0',
      'latest_version_ios': '2.6.0',
      'update_message': 'legacy update',
      'update_message_ar': 'حدّث التطبيق',
      'update_message_en': 'Update the app',
      'store_url_android': 'https://example.com/android',
      'store_url_ios': 'https://example.com/ios',
    });

    expect(model.id, '1');
    expect(model.isMaintenanceMode, isTrue);
    expect(model.maintenanceMessageAr, 'صيانة');
    expect(model.maintenanceMessageEn, 'Maintenance');
    expect(model.expectedEndTime, DateTime.parse('2026-10-01T12:00:00Z'));
    expect(model.minAndroidVersion, '2.1.0');
    expect(model.minIosVersion, '2.2.0');
    expect(model.latestAndroidVersion, '2.5.0');
    expect(model.latestIosVersion, '2.6.0');
    expect(model.updateMessageAr, 'حدّث التطبيق');
    expect(model.updateMessageEn, 'Update the app');
  });

  test('falls back to legacy single-language messages', () {
    final model = AppStatusModel.fromJson(const {
      'maintenance_mode': false,
      'maintenance_message': 'Legacy maintenance',
      'update_message': 'Legacy update',
    });

    expect(model.maintenanceMessageAr, 'Legacy maintenance');
    expect(model.maintenanceMessageEn, 'Legacy maintenance');
    expect(model.updateMessageAr, 'Legacy update');
    expect(model.updateMessageEn, 'Legacy update');
  });
}
