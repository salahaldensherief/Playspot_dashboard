import 'package:equatable/equatable.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingSuccess extends OnboardingState {
  final Lounge lounge;
  const OnboardingSuccess(this.lounge);

  @override
  List<Object?> get props => [lounge];
}

class OnboardingError extends OnboardingState {
  final String message;
  const OnboardingError(this.message);

  @override
  List<Object?> get props => [message];
}
