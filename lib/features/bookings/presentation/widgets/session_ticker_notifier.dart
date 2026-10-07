import 'dart:async';
import 'package:flutter/foundation.dart';

class SessionTickerNotifier extends ChangeNotifier {
  final DateTime Function() _clock;
  late DateTime _now;
  Timer? _timer;
  final Duration _interval;
  DateTime get now => _now;
  DateTime Function() get clock => _clock;

  SessionTickerNotifier({
    DateTime Function()? clock,
    Duration interval = const Duration(seconds: 1),
    bool enabled = true,
  }) : _clock = clock ?? DateTime.now,
       _interval = interval {
    _now = _clock();
    setEnabled(enabled);
  }

  void setEnabled(bool enabled) {
    if (!enabled) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_timer != null) return;
    _now = _clock();
    notifyListeners();
    _timer = Timer.periodic(_interval, (_) {
      _now = _clock();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
