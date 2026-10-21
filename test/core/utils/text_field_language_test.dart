import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';
import 'package:play_spot_dashboard/core/utils/text_field_language.dart';

void main() {
  test(
    'Arabic fields reject Latin letters while keeping numbers and symbols',
    () {
      expect(
        AppValidator.matchesLanguage(
          'صالة 5 - فرع (2)',
          TextFieldLanguage.arabic,
        ),
        isTrue,
      );
      expect(
        AppValidator.matchesLanguage('صالة PlaySpot', TextFieldLanguage.arabic),
        isFalse,
      );
      expect(
        AppValidator.matchesLanguage('Café', TextFieldLanguage.arabic),
        isFalse,
      );
    },
  );

  test('English fields reject Arabic text including pasted mixed text', () {
    expect(
      AppValidator.matchesLanguage(
        'PlaySpot 5 - Branch (2)',
        TextFieldLanguage.english,
      ),
      isTrue,
    );
    expect(
      AppValidator.matchesLanguage('PlaySpot صالة', TextFieldLanguage.english),
      isFalse,
    );
    expect(
      AppValidator.matchesLanguage('فرع', TextFieldLanguage.english),
      isFalse,
    );
  });

  test('empty and unrestricted fields keep their own validation policy', () {
    expect(AppValidator.matchesLanguage('', TextFieldLanguage.arabic), isTrue);
    expect(
      AppValidator.matchesLanguage('test عربي', TextFieldLanguage.unrestricted),
      isTrue,
    );
  });
}
