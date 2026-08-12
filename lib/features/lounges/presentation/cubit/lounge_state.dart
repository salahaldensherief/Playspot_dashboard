import 'package:equatable/equatable.dart';
import '../../domain/entities/lounge.dart';

enum LoungeStatus { initial, loading, success, failure }

class LoungeState extends Equatable {
  final LoungeStatus status;
  final List<Lounge> lounges;
  final String? errorMessage;

  const LoungeState({
    this.status = LoungeStatus.initial,
    this.lounges = const [],
    this.errorMessage,
  });

  LoungeState copyWith({
    LoungeStatus? status,
    List<Lounge>? lounges,
    String? errorMessage,
  }) {
    return LoungeState(
      status: status ?? this.status,
      lounges: lounges ?? this.lounges,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, lounges, errorMessage];
}
