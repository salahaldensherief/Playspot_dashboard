import 'package:flutter/material.dart';
import 'session_ticker_notifier.dart';
export 'session_ticker_notifier.dart';

class SessionTickerScope extends InheritedNotifier<SessionTickerNotifier> {
  const SessionTickerScope({
    super.key,
    required SessionTickerNotifier ticker,
    required super.child,
  }) : super(notifier: ticker);

  static DateTime nowOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<SessionTickerScope>()
            ?.notifier
            ?.now ??
        DateTime.now();
  }

  static DateTime Function() clockOf(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<SessionTickerScope>()
          ?.notifier
          ?.clock ??
      DateTime.now;
}
