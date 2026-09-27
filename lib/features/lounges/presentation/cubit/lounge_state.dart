import 'package:equatable/equatable.dart';
import '../../domain/entities/lounge.dart';

enum LoungeStatus { initial, loading, success, failure }

class LoungeState extends Equatable {
  final LoungeStatus status;
  final List<Lounge> lounges;
  final String? selectedLoungeId;
  final String? errorMessage;

  Lounge? get selectedLounge {
    if (selectedLoungeId == null) return lounges.firstOrNull;
    for (final l in lounges) {
      if (l.id == selectedLoungeId) return l;
    }
    return lounges.firstOrNull;
  }

  const LoungeState({
    this.status = LoungeStatus.initial,
    this.lounges = const [],
    this.selectedLoungeId,
    this.errorMessage,
  });

  LoungeState copyWith({
    LoungeStatus? status,
    List<Lounge>? lounges,
    String? selectedLoungeId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoungeState(
      status: status ?? this.status,
      lounges: lounges ?? this.lounges,
      selectedLoungeId: selectedLoungeId ?? this.selectedLoungeId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, lounges, selectedLoungeId, errorMessage];
}
