import 'dart:async';
import 'package:flutter/material.dart';

class SessionTickerNotifier extends ChangeNotifier {
  Timer? _timer;
  DateTime _now = DateTime.now();

  DateTime get now => _now;

  SessionTickerNotifier({Duration interval = const Duration(seconds: 1)}) {
    _timer = Timer.periodic(interval, (_) {
      _now = DateTime.now();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

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
}
