import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled alert WAV contains complete PCM frames and valid RIFF sizes',
    () async {
      final data = await rootBundle.load('assets/audio/notification.wav');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      String tag(int start) =>
          String.fromCharCodes(bytes.sublist(start, start + 4));
      expect(tag(0), 'RIFF');
      expect(tag(8), 'WAVE');
      expect(data.getUint32(4, Endian.little) + 8, bytes.length);
      expect(
        data.getUint16(20, Endian.little),
        1,
      ); // PCM, existing tone unchanged.
      final channels = data.getUint16(22, Endian.little);
      final bits = data.getUint16(34, Endian.little);
      expect(channels, 1);
      expect(bits, 8);
      var offset = 12;
      while (tag(offset) != 'data') {
        final size = data.getUint32(offset + 4, Endian.little);
        offset += 8 + size + size % 2;
        expect(offset + 8, lessThanOrEqualTo(bytes.length));
      }
      final samples = data.getUint32(offset + 4, Endian.little);
      expect(offset + 8 + samples + samples % 2, bytes.length);
      expect(samples % (channels * bits ~/ 8), 0);
      expect(samples / data.getUint32(28, Endian.little), greaterThan(0.1));
      expect(
        bytes.sublist(offset + 8, offset + 8 + samples).toSet().length,
        greaterThan(8),
      );
    },
  );
}
