import '../../domain/entities/onboarding_venue_payload.dart';
import '../../domain/entities/onboarding_extra_payload.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_multi_image_picker.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/local_cache_service.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import '../../../lounges/domain/entities/extra_entity.dart';
import '../../../lounges/domain/entities/lounge.dart';
import '../../../rooms/domain/entities/room_entity.dart';
import '../../domain/entities/lounge_draft_params.dart';
import '../../domain/entities/onboarding_room_payload.dart';
import '../../domain/usecases/add_extra_usecase.dart';
import '../../domain/usecases/add_room_usecase.dart';
import '../../domain/usecases/batch_complete_onboarding_usecase.dart';
import 'onboarding_state.dart';
import '../../domain/usecases/get_saved_onboarding_draft_usecase.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final GetSavedOnboardingDraftUseCase getSavedDraftUseCase;
  final AddRoomUseCase addRoomUseCase;
  final AddExtraUseCase addExtraUseCase;
  final BatchCompleteOnboardingUseCase batchCompleteOnboardingUseCase;
  final LocationService locationService;
  final LocalCacheService localCacheService;

  String? _draftKey;
  String? _draftLoungeId;
  int _restoreGeneration = 0;

  OnboardingCubit({
    required this.addRoomUseCase,
    required this.getSavedDraftUseCase,
    required this.addExtraUseCase,
    required this.batchCompleteOnboardingUseCase,
    required this.locationService,
    required this.localCacheService,
  }) : super(const OnboardingState());

  void restoreDraft({required String ownerId, required String loungeId}) {
    if (isClosed || ownerId.isEmpty || loungeId.isEmpty) return;
    final key = 'cache_onboarding_v2_${ownerId}_$loungeId';
    if (_draftKey != key) {
      ++_restoreGeneration;
      emit(const OnboardingState());
    }
    _draftKey = key;
    _draftLoungeId = loungeId;
    try {
      final json = localCacheService.getJson(_draftKey!);
      if (json is Map) {
        final draftParams = LoungeDraftParams.fromJson(
          Map<String, dynamic>.from(json),
        );
        emit(state.copyWith(draft: draftParams));
      }
    } catch (_) {}
  }

  Future<void> restoreSavedDraft(String loungeId) async {
    if (isClosed || state.status == OnboardingStatus.loading) return;
    if (_draftLoungeId != null && _draftLoungeId != loungeId) return;
    final generation = ++_restoreGeneration;
    emit(state.copyWith(status: OnboardingStatus.loading));
    final result = await getSavedDraftUseCase(loungeId);
    if (isClosed || generation != _restoreGeneration) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (saved) => emit(
        state.copyWith(
          status: OnboardingStatus.restored,
          draft: state.draft.name.trim().isNotEmpty
              ? state.draft
              : saved.fields,
          lounge: saved.lounge,
          reviewNotes: saved.reviewNotes,
          rooms: state.rooms.isNotEmpty ? state.rooms : saved.rooms,
          extras: state.extras.isNotEmpty ? state.extras : saved.extras,
        ),
      ),
    );
  }

  void saveDraft(LoungeDraftParams draft) {
    try {
      emit(
        state.copyWith(
          draft: draft,
          status: state.status == OnboardingStatus.saved && draft != state.draft
              ? OnboardingStatus.initial
              : state.status,
        ),
      );
      final key = _draftKey;
      if (key != null) localCacheService.setJson(key, draft.toJson());
    } catch (_) {}
  }

  void setStep(int step) {
    if (step >= 0 && step <= 8) {
      saveDraft(state.draft.copyWith(step: step));
    }
  }

  void nextStep() {
    if (state.currentStep < 8) {
      setStep(state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      setStep(state.currentStep - 1);
    }
  }

  void clearDraft() {
    try {
      emit(state.copyWith(draft: const LoungeDraftParams()));
      final key = _draftKey;
      if (key != null) localCacheService.remove(key);
    } catch (_) {}
  }

  void markReviewSubmitted() {
    if (isClosed || state.status != OnboardingStatus.saved) return;
    clearDraft();
    emit(state.copyWith(status: OnboardingStatus.completed));
  }

  Future<void> addNewRoom(RoomEntity room) async {
    emit(state.copyWith(status: OnboardingStatus.loading));
    final result = await addRoomUseCase(room);

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (newRoom) => emit(
        state.copyWith(
          status: OnboardingStatus.success,
          rooms: [...state.rooms, newRoom],
        ),
      ),
    );
  }

  void removeRoom(String roomId) {
    final updatedRooms = state.rooms.where((r) => r.id != roomId).toList();
    emit(state.copyWith(rooms: updatedRooms));
  }

  Future<void> addNewExtra(ExtraEntity extra) async {
    emit(state.copyWith(status: OnboardingStatus.loading));
    final result = await addExtraUseCase(extra);

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (newExtra) => emit(
        state.copyWith(
          status: OnboardingStatus.success,
          extras: [...state.extras, newExtra],
        ),
      ),
    );
  }

  Future<void> submitLounge({
    required Lounge lounge,
    Uint8List? mainImageBytes,
    String? mainImageName,
    List<SelectedImage>? galleryImages,
    required String loungeId,
    BuildContext? context,
  }) async {
    if (isClosed || state.status == OnboardingStatus.loading) return;
    final submittedDraft = state.draft;
    final submittedRooms = List<RoomEntity>.of(state.rooms);
    final submittedExtras = List<ExtraEntity>.of(state.extras);
    emit(state.copyWith(status: OnboardingStatus.loading));

    try {
      String mainImageUrl = lounge.imageUrl;
      if (mainImageBytes != null && mainImageName != null) {
        mainImageUrl = await sl<StorageService>().uploadLoungeImage(
          mainImageBytes,
          mainImageName,
          loungeId,
        );
      }

      List<String> galleryUrls = List.of(lounge.images ?? const <String>[]);
      if (galleryImages != null && galleryImages.isNotEmpty) {
        final uploadedUrls = await sl<StorageService>().uploadLoungeImages(
          galleryImages.map((e) => e.bytes).toList(),
          galleryImages.map((e) => e.name).toList(),
          loungeId,
        );
        galleryUrls = {...galleryUrls, ...uploadedUrls}.toList();
      }

      final loungeData = OnboardingVenuePayload.fromDraft(
        lounge: lounge,
        draft: submittedDraft,
        imageUrl: mainImageUrl,
        galleryUrls: galleryUrls,
      );

      final roomsData = submittedRooms
          .map(OnboardingRoomPayload.fromRoom)
          .toList();

      final extrasData = submittedExtras
          .map(OnboardingExtraPayload.fromExtra)
          .toList();

      final result = await batchCompleteOnboardingUseCase(
        loungeId: loungeId,
        loungeData: loungeData,
        rooms: roomsData,
        extras: extrasData,
      );

      if (isClosed) return;

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: OnboardingStatus.failure,
            errorMessage: failure.message,
          ),
        ),
        (newLounge) {
          emit(
            state.copyWith(status: OnboardingStatus.saved, lounge: newLounge),
          );
        },
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
