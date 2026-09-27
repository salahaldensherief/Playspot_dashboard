import 'dart:async';
import 'package:flutter/foundation.dart';

/// A utility class for debouncing quick successive actions (such as search text input
/// or rapid realtime stream events) to prevent redundant queries and UI re-renders.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 400)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}
