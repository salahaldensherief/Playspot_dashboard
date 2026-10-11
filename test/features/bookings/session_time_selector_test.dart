import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_clock_host.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_time_builder.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_time_selector.dart';

void main() {
  testWidgets(
    'only phase changes rebuild static content while time keeps ticking',
    (tester) async {
      var now = DateTime(2026);
      var staticBuilds = 0;
      var timerBuilds = 0;
      final deadline = now.add(const Duration(seconds: 4));
      final label = ValueNotifier('original');

      await tester.pumpWidget(
        MaterialApp(
          home: SessionClockHost(
            clock: () => now,
            child: ValueListenableBuilder<String>(
              valueListenable: label,
              builder: (_, value, __) => SessionTimeSelector<bool>(
                select: (time) => !time.isBefore(deadline),
                builder: (_, expired) => Column(
                  children: [
                    Builder(
                      builder: (_) {
                        staticBuilds++;
                        return Text('$value:$expired');
                      },
                    ),
                    SessionTimeBuilder(
                      builder: (_, time) {
                        timerBuilds++;
                        return Text(time.toIso8601String());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final before = timerBuilds;
      for (var i = 0; i < 3; i++) {
        now = now.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }
      expect(staticBuilds, 1);
      expect(timerBuilds, greaterThan(before));
      now = deadline;
      await tester.pump(const Duration(seconds: 1));
      expect(staticBuilds, 2);
      expect(find.text('original:true'), findsOneWidget);
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(staticBuilds, 2);
      label.value = 'updated';
      await tester.pump();
      expect(find.text('updated:true'), findsOneWidget);
      expect(staticBuilds, 3);
      await tester.pumpWidget(const SizedBox());
      label.dispose();
    },
  );
}
