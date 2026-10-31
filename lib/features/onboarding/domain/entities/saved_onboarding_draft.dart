import 'package:equatable/equatable.dart';
import '../../../lounges/domain/entities/lounge.dart';
import '../../../lounges/domain/entities/extra_entity.dart';
import '../../../rooms/domain/entities/room_entity.dart';
import 'lounge_draft_params.dart';

class SavedOnboardingDraft extends Equatable {
  final String? reviewNotes;
  final Lounge lounge;
  final LoungeDraftParams fields;
  final List<RoomEntity> rooms;
  final List<ExtraEntity> extras;
  const SavedOnboardingDraft({
    this.reviewNotes,
    required this.lounge,
    required this.fields,
    required this.rooms,
    required this.extras,
  });
  @override
  List<Object?> get props => [lounge, fields, rooms, extras, reviewNotes];
}
