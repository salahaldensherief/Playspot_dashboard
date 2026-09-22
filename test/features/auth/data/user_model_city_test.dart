import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel & Profile City & Payload Sanitization Tests', () {
    const validCityUuid = 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d';

    test('Case 1: User with selected city (valid UUID and embedded cities object)', () {
      final jsonResponse = {
        'id': 'user-123',
        'email': 'user@example.com',
        'full_name': 'أحمد علي',
        'role': 'user',
        'city_id': validCityUuid,
        'cities': {
          'id': validCityUuid,
          'name_ar': 'القاهرة',
          'name_en': 'Cairo',
        },
        'is_setup_completed': true,
      };

      final user = UserModel.fromJson(jsonResponse);

      // Verify model parsing
      expect(user.id, equals('user-123'));
      expect(user.cityId, equals(validCityUuid));
      expect(user.cityNameAr, equals('القاهرة'));
      expect(user.cityNameEn, equals('Cairo'));

      // Verify localized city display
      expect(user.getDisplayCityName(languageCode: 'ar'), equals('القاهرة'));
      expect(user.getDisplayCityName(languageCode: 'en'), equals('Cairo'));
      expect(user.displayCityName, equals('القاهرة'));

      // Verify toJson payload contains valid city_id
      final json = user.toJson();
      expect(json['city_id'], equals(validCityUuid));
      expect(json.containsKey('city_id'), isTrue);
    });

    test('Case 2: User without city or with city_id="undefined" / null values', () {
      final jsonWithUndefinedCity = {
        'id': 'user-456',
        'email': 'nocity@example.com',
        'full_name': 'محمد خالد',
        'role': 'user',
        'city_id': 'undefined',
        'city_name_ar': null,
        'city_name_en': null,
        'is_setup_completed': false,
      };

      final user = UserModel.fromJson(jsonWithUndefinedCity);

      // Verify cityId is cleaned to null
      expect(user.cityId, isNull);
      expect(user.cityNameAr, isNull);
      expect(user.cityNameEn, isNull);
      expect(user.getDisplayCityName(languageCode: 'ar'), isNull);
      expect(user.getDisplayCityName(languageCode: 'en'), isNull);

      // Verify toJson strips city_id and null values
      final json = user.toJson();
      expect(json.containsKey('city_id'), isFalse);
      expect(json.containsValue('undefined'), isFalse);
      expect(json.containsValue(null), isFalse);

      // Verify sanitizeProfilePayload explicitly strips city_id="undefined" and null keys
      final rawPatchPayload = <String, dynamic>{
        'full_name': 'محمد خالد الجديد',
        'city_id': 'undefined',
        'lounge_id': 'null',
        'avatar_url': null,
        'phone': '01012345678',
      };

      final sanitizedPayload = UserModel.sanitizeProfilePayload(rawPatchPayload);

      expect(sanitizedPayload, equals({
        'full_name': 'محمد خالد الجديد',
        'phone': '01012345678',
      }));
      expect(sanitizedPayload.containsKey('city_id'), isFalse);
      expect(sanitizedPayload.containsKey('lounge_id'), isFalse);
      expect(sanitizedPayload.containsKey('avatar_url'), isFalse);
    });
  });
}
