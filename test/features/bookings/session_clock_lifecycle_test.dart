import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_clock_host.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_time_builder.dart';

void main() {
  testWidgets('clock only rebuilds time consumers and stops after disposal', (
    tester,
  ) async {
    var staticBuilds = 0;
    var liveBuilds = 0;
    var reads = 0;
    DateTime clock() => DateTime(2026).add(Duration(seconds: reads++));
    await tester.pumpWidget(MaterialApp(
      home: SessionClockHost(
        clock: clock,
        child: Column(children: [
          Builder(builder: (_) {
            staticBuilds++;
            return const Text('static');
          }),
          SessionClockHost(child: SessionTimeBuilder(builder: (_, now) {
            liveBuilds++;
            return Text(now.toIso8601String());
          })),
        ]),
      ),
    ));
    final before = reads;
    final builds = liveBuilds;
    await tester.pump(const Duration(seconds: 3));
    expect(reads - before, 3);
    expect(staticBuilds, 1);
    expect(liveBuilds, greaterThan(builds));
    await tester.pumpWidget(const SizedBox());
    final after = reads;
    await tester.pump(const Duration(seconds: 3));
    expect(reads, after);
  });

  testWidgets('hidden and background hosts stop ticking', (tester) async {
    var reads = 0;
    final visible = ValueNotifier(true);
    DateTime clock() => DateTime(2026).add(Duration(seconds: reads++));
    await tester.pumpWidget(MaterialApp(
      home: ValueListenableBuilder<bool>(
        valueListenable: visible,
        builder: (_, enabled, child) => TickerMode(enabled: enabled, child: child!),
        child: SessionClockHost(clock: clock, child: const SizedBox()),
      ),
    ));
    visible.value = false;
    await tester.pump();
    final hidden = reads;
    await tester.pump(const Duration(seconds: 3));
    expect(reads, hidden);
    visible.value = true;
    await tester.pump();
    expect(reads, greaterThan(hidden));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final paused = reads;
    await tester.pump(const Duration(seconds: 3));
    expect(reads, paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(reads, greaterThan(paused));
    await tester.pumpWidget(const SizedBox());
    visible.dispose();
  });
}
