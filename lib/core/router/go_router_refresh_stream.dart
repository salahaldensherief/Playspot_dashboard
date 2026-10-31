import 'dart:async';
import 'package:flutter/material.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(
    Stream<dynamic> stream, {
    List<Stream<dynamic>> additionalStreams = const [],
  }) {
    for (final source in [stream, ...additionalStreams]) {
      _subscriptions.add(
        source.asBroadcastStream().listen((dynamic _) {
          if (hasListeners) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (hasListeners) {
                notifyListeners();
              }
            });
            WidgetsBinding.instance.ensureVisualUpdate();
          }
        }),
      );
    }
  }

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
