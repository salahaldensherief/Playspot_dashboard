import 'package:equatable/equatable.dart';
import '../../../lounges/domain/entities/extra_entity.dart';
import '../../../lounges/domain/entities/lounge.dart';
import '../../../rooms/domain/entities/room_entity.dart';
import '../../domain/entities/lounge_draft_params.dart';

enum OnboardingStatus { initial, loading, success, completed, failure }

class OnboardingState extends Equatable {
  final OnboardingStatus status;
  final List<RoomEntity> rooms;
  final List<ExtraEntity> extras;
  final Lounge? lounge;
  final String? errorMessage;
  final LoungeDraftParams draft;

  int get currentStep => draft.step;

  const OnboardingState({
    this.status = OnboardingStatus.initial,
    this.rooms = const [],
    this.extras = const [],
    this.lounge,
    this.errorMessage,
    this.draft = const LoungeDraftParams(),
  });

  OnboardingState copyWith({
    OnboardingStatus? status,
    List<RoomEntity>? rooms,
    List<ExtraEntity>? extras,
    Lounge? lounge,
    String? errorMessage,
    LoungeDraftParams? draft,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      extras: extras ?? this.extras,
      lounge: lounge ?? this.lounge,
      errorMessage: errorMessage ?? this.errorMessage,
      draft: draft ?? this.draft,
    );
  }

  @override
  List<Object?> get props => [
        status,
        rooms,
        extras,
        lounge,
        errorMessage,
        draft,
      ];
}
