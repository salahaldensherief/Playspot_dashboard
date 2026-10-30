import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'brand font resolves from assets with network fetching forbidden',
    () async {
      final original = GoogleFonts.config.allowRuntimeFetching;
      addTearDown(() => GoogleFonts.config.allowRuntimeFetching = original);
      GoogleFonts.config.allowRuntimeFetching = false;
      final style = GoogleFonts.orbitron();
      await GoogleFonts.pendingFonts([style]);
      expect(style.fontFamily, startsWith('Orbitron'));
    },
  );
}
