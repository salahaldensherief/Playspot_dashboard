import 'package:flutter/material.dart';

import 'session_clock_host.dart';
import 'session_ticker.dart';

class SessionTimeBuilder extends StatelessWidget {
  final Widget Function(BuildContext, DateTime) builder;

  const SessionTimeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    if (context.getInheritedWidgetOfExactType<SessionTickerScope>() == null) {
      return SessionClockHost(child: SessionTimeBuilder(builder: builder));
    }
    return builder(context, SessionTickerScope.nowOf(context));
  }
}
