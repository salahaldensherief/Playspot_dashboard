import 'dart:async';
import 'package:flutter/foundation.dart';

class SessionTickerNotifier extends ChangeNotifier {
  final DateTime Function() _clock;
  late DateTime _now;
  Timer? _timer;
  DateTime get now => _now;
  DateTime Function() get clock => _clock;

  SessionTickerNotifier({
    DateTime Function()? clock,
    Duration interval = const Duration(seconds: 1),
  }) : _clock = clock ?? DateTime.now {
    _now = _clock();
    _timer = Timer.periodic(interval, (_) {
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
