import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Mixin to handle realtime stream subscriptions across Cubits cleanly,
/// preventing duplicate subscriptions and ensuring proper lifecycle cleanup.
mixin RealtimeWatcherMixin<S> on Cubit<S> {
  StreamSubscription? realtimeSubscription;
  String? watchedEntityId;

  /// Returns true if watching can be skipped (e.g. already watching same entityId and not forcing refresh)
  bool isAlreadyWatching(String? entityId, {bool forceRefresh = false}) {
    final cleanId = entityId?.trim();
    if (cleanId == null || cleanId.isEmpty) return true;
    return !forceRefresh && realtimeSubscription != null && watchedEntityId == cleanId;
  }

  /// Starts watching a stream for the given entityId, canceling any previous subscription.
  void startWatch<T>({
    required String entityId,
    required Stream<T> stream,
    required void Function(T data) onData,
    void Function(Object error)? onError,
  }) {
    final cleanId = entityId.trim();
    watchedEntityId = cleanId;
    cancelRealtimeSubscription();

    realtimeSubscription = stream.listen(
      (data) {
        if (isClosed) return;
        onData(data);
      },
      onError: (error) {
        if (isClosed) return;
        if (onError != null) {
          onError(error);
        }
      },
    );
  }

  /// Safely cancels the active realtime subscription.
  void cancelRealtimeSubscription() {
    realtimeSubscription?.cancel();
    realtimeSubscription = null;
  }

  @override
  Future<void> close() {
    cancelRealtimeSubscription();
    return super.close();
  }
}
