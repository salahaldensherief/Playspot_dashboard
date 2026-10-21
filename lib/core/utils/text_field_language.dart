enum TextFieldLanguage { unrestricted, arabic, english }

final _arabicScript = RegExp(
  r'[\u0600-\u06FF\u0750-\u077F\u0870-\u089F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
);
final _latinScript = RegExp(
  r'[A-Za-z\u00C0-\u024F\u1E00-\u1EFF\u2C60-\u2C7F\uA720-\uA7FF]',
);

bool matchesTextLanguage(String? value, TextFieldLanguage language) {
  if (value == null || value.trim().isEmpty) return true;
  return switch (language) {
    TextFieldLanguage.unrestricted => true,
    TextFieldLanguage.arabic => !_latinScript.hasMatch(value),
    TextFieldLanguage.english => !_arabicScript.hasMatch(value),
  };
}
