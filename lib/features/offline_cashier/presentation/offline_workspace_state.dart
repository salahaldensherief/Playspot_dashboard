import 'package:equatable/equatable.dart';

enum OfflineWorkspaceStatus { initial, loading, ready, failure }

class OfflineWorkspaceState extends Equatable {
  final OfflineWorkspaceStatus status;
  final Map<String, dynamic> snapshot;
  final String? error;
  final bool busy;
  const OfflineWorkspaceState({
    this.status = OfflineWorkspaceStatus.initial,
    this.snapshot = const {},
    this.error,
    this.busy = false,
  });
  OfflineWorkspaceState copyWith({
    OfflineWorkspaceStatus? status,
    Map<String, dynamic>? snapshot,
    String? error,
    bool? busy,
  }) => OfflineWorkspaceState(
    status: status ?? this.status,
    snapshot: snapshot ?? this.snapshot,
    error: error,
    busy: busy ?? this.busy,
  );
  int get pending => (snapshot['outbox'] as List? ?? const []).length;
  bool get prepared => snapshot['bootstrap'] is Map;
  bool get canOperate =>
      prepared &&
      snapshot['writer_release'] == null &&
      snapshot['authority_review_required'] != true &&
      (snapshot['authority'] as Map?)?['online_requested'] == false;

  Map<String, dynamic> get visibleBookings {
    final cached = snapshot['bookings'] as Map? ?? {};
    final server = snapshot['server_bookings'] as Map? ?? {};
    final outbox = snapshot['outbox'] as List? ?? [];
    final receipts = snapshot['receipts'] as Map? ?? {};
    return {
      for (final entry in cached.entries)
        entry.key.toString(): _visibleBooking(
          entry.key,
          entry.value,
          server,
          outbox,
          receipts,
        ),
    };
  }

  Map _visibleBooking(
    Object id,
    Object? value,
    Map server,
    List outbox,
    Map receipts,
  ) {
    final local = Map<String, dynamic>.from(value as Map);
    final ack = server[id];
    if (ack is! Map ||
        outbox.any((op) => op is Map && op['booking_id'] == id)) {
      return local;
    }
    final localSequences = receipts.values
        .whereType<Map>()
        .where((op) => op['booking_id'] == id)
        .map((op) => op['sequence'])
        .whereType<int>();
    if (localSequences.isEmpty) return local;
    final latest = localSequences.reduce((a, b) => a > b ? a : b);
    if (ack['last_sequence'] != latest) return local;
    return {
      ...local,
      ...Map<String, dynamic>.from(ack),
      'sync_status': 'synced',
    };
  }

  @override
  List<Object?> get props => [status, snapshot, error, busy];
}
