part of 'onboarding_cubit.dart';

enum OnboardingStatus { initial, loading, success, failure }

class OnboardingState extends Equatable {
  final int currentStep;
  final OnboardingStatus status;
  final List<RoomEntity> rooms;
  final List<ExtraEntity> extras;
  final Lounge? lounge;
  final String? errorMessage;

  const OnboardingState({
    this.currentStep = 1,
    this.status = OnboardingStatus.initial,
    this.rooms = const [],
    this.extras = const [],
    this.lounge,
    this.errorMessage,
  });

  OnboardingState copyWith({
    int? currentStep,
    OnboardingStatus? status,
    List<RoomEntity>? rooms,
    List<ExtraEntity>? extras,
    Lounge? lounge,
    String? errorMessage,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      extras: extras ?? this.extras,
      lounge: lounge ?? this.lounge,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [currentStep, status, rooms, extras, lounge, errorMessage];
}
