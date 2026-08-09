part of 'lounge_cubit.dart';

abstract class LoungeState extends Equatable {
  const LoungeState();

  @override
  List<Object?> get props => [];
}

class LoungeInitial extends LoungeState {}

class LoungeLoading extends LoungeState {}

class LoungeLoaded extends LoungeState {
  final List<Lounge> lounges;

  const LoungeLoaded(this.lounges);

  @override
  List<Object?> get props => [lounges];
}

class LoungeError extends LoungeState {
  final String message;

  const LoungeError(this.message);

  @override
  List<Object?> get props => [message];
}
