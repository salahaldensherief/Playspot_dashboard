import 'package:flutter/material.dart';

import 'session_clock_host.dart';
import 'session_ticker.dart';

class SessionTimeBuilder extends StatelessWidget {
  final Widget Function(BuildContext, DateTime) builder;

  const SessionTimeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<SessionTickerScope>();
    if (scope == null) {
      return SessionClockHost(child: SessionTimeBuilder(builder: builder));
    }
    final ticker = scope.notifier!;
    if (!TickerMode.of(context)) return builder(context, ticker.now);
    return AnimatedBuilder(
      animation: ticker,
      builder: (context, child) => builder(context, ticker.now),
    );
  }
}
