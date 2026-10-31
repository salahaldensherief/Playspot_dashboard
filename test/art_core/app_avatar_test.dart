import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_avatar.dart';

class _UndecodableAvatar extends ImageProvider<int> {
  @override
  Future<int> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(1);
  @override
  ImageStreamCompleter loadImage(int key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(StateError('source image cannot be decoded')),
      );
}

void main() {
  testWidgets('missing avatar retains the identity fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppAvatar(radius: 20, imageUrl: ' ', fallback: Text('A')),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('decode errors retain fallback without a framework exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppAvatar(
          radius: 20,
          imageProvider: _UndecodableAvatar(),
          fallback: const Text('A'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
