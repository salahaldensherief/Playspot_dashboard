import 'dart:async';

Stream<T> refreshingStream<T>({
  required Future<T> Function() fetch,
  required Stream<Object?> Function() invalidations,
  Duration debounce = const Duration(milliseconds: 300),
  Duration pollInterval = const Duration(seconds: 30),
  void Function(Object)? onRealtimeError,
}) {
  late StreamController<T> controller;
  StreamSubscription<Object?>? subscription;
  Timer? debounceTimer;
  Timer? pollTimer;
  var active = false;
  var paused = false;
  var fetching = false;
  var pending = false;

  Future<void> refresh() async {
    if (!active) return;
    pending = true;
    if (fetching || paused) return;
    fetching = true;
    try {
      while (active && !paused && pending) {
        debounceTimer?.cancel();
        pending = false;
        try {
          final result = await fetch();
          if (active && !paused) controller.add(result);
        } catch (error, stack) {
          if (active && !paused) controller.addError(error, stack);
        }
      }
    } finally {
      fetching = false;
    }
  }

  void scheduleRefresh() {
    if (!active) return;
    pending = true;
    if (paused) return;
    debounceTimer?.cancel();
    debounceTimer = Timer(debounce, () => unawaited(refresh()));
  }

  void startPolling() {
    pollTimer?.cancel();
    pollTimer = Timer.periodic(pollInterval, (_) => scheduleRefresh());
  }

  controller = StreamController<T>(
    onListen: () {
      active = true;
      unawaited(refresh());
      try {
        subscription = invalidations().listen(
          (_) => scheduleRefresh(),
          onError: (Object error) => onRealtimeError?.call(error),
        );
      } catch (error) {
        onRealtimeError?.call(error);
      }
      startPolling();
    },
    onPause: () {
      paused = true;
      debounceTimer?.cancel();
      pollTimer?.cancel();
    },
    onResume: () {
      paused = false;
      startPolling();
      unawaited(refresh());
    },
    onCancel: () async {
      active = false;
      pending = false;
      debounceTimer?.cancel();
      pollTimer?.cancel();
      unawaited(controller.close());
      await subscription?.cancel();
      subscription = null;
    },
  );
  return controller.stream;
}
