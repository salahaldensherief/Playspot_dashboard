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
import '../../domain/usecases/add_extra_usecase.dart';
import '../../domain/usecases/add_room_usecase.dart';
import '../../domain/usecases/setup_lounge_usecase.dart';
import '../../domain/usecases/batch_complete_onboarding_usecase.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final AddRoomUseCase addRoomUseCase;
  final AddExtraUseCase addExtraUseCase;
  final SetupLoungeUseCase setupLoungeUseCase;
  final BatchCompleteOnboardingUseCase batchCompleteOnboardingUseCase;
  final LocationService locationService;
  final LocalCacheService localCacheService;

  static const String _draftKey = 'cache_onboarding_lounge_draft_v1';

  OnboardingCubit({
    required this.addRoomUseCase,
    required this.addExtraUseCase,
    required this.setupLoungeUseCase,
    required this.batchCompleteOnboardingUseCase,
    required this.locationService,
    required this.localCacheService,
  }) : super(const OnboardingState()) {
    restoreDraft();
  }

  void restoreDraft() {
    try {
      final json = localCacheService.getJson(_draftKey);
      if (json is Map) {
        final draftParams = LoungeDraftParams.fromJson(Map<String, dynamic>.from(json));
        emit(state.copyWith(draft: draftParams));
      }
    } catch (_) {}
  }

  void saveDraft(LoungeDraftParams draft) {
    try {
      emit(state.copyWith(draft: draft));
      localCacheService.setJson(_draftKey, draft.toJson());
    } catch (_) {}
  }

  void setStep(int step) {
    if (step >= 0 && step <= 6) {
      saveDraft(state.draft.copyWith(step: step));
    }
  }

  void nextStep() {
    if (state.currentStep < 6) {
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
      localCacheService.remove(_draftKey);
    } catch (_) {}
  }

  Future<void> addNewRoom(RoomEntity room) async {
    emit(state.copyWith(status: OnboardingStatus.loading));
    final result = await addRoomUseCase(room);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: OnboardingStatus.failure,
        errorMessage: failure.message,
      )),
      (newRoom) => emit(state.copyWith(
        status: OnboardingStatus.success,
        rooms: [...state.rooms, newRoom],
      )),
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
      (failure) => emit(state.copyWith(
        status: OnboardingStatus.failure,
        errorMessage: failure.message,
      )),
      (newExtra) => emit(state.copyWith(
        status: OnboardingStatus.success,
        extras: [...state.extras, newExtra],
      )),
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
    emit(state.copyWith(status: OnboardingStatus.loading));
    
    try {
      String mainImageUrl = '';
      if (mainImageBytes != null && mainImageName != null) {
        mainImageUrl = await sl<StorageService>().uploadLoungeImage(mainImageBytes, mainImageName, loungeId);
      }

      List<String> galleryUrls = [];
      if (galleryImages != null && galleryImages.isNotEmpty) {
        galleryUrls = await sl<StorageService>().uploadLoungeImages(
          galleryImages.map((e) => e.bytes).toList(),
          galleryImages.map((e) => e.name).toList(),
          loungeId,
        );
      }

      final cleanOpensAt = lounge.opensAt.isNotEmpty ? lounge.opensAt : '10:00';
      final cleanClosesAt = lounge.closesAt.isNotEmpty ? lounge.closesAt : '02:00';

      final loungeData = <String, dynamic>{
        'name': lounge.name,
        'name_ar': lounge.name,
        'name_en': lounge.name,
        if (state.draft.brandName.isNotEmpty) 'brand_name': state.draft.brandName,
        if (state.draft.branchName.isNotEmpty) 'branch_name': state.draft.branchName,
        'city': lounge.city ?? '',
        'location': lounge.location ?? '',
        'opening_time': cleanOpensAt,
        'closing_time': cleanClosesAt,
        'image_url': mainImageUrl,
        'images': galleryUrls,
        'description_ar': lounge.descriptionAr ?? lounge.descriptionEn ?? '',
        'description_en': lounge.descriptionEn ?? lounge.descriptionAr ?? '',
        'address': lounge.location ?? '',
        if (lounge.lat != null) 'lat': lounge.lat,
        if (lounge.lng != null) 'lng': lounge.lng,
      };

      final roomsData = state.rooms.map((r) => {
        'name': r.nameEn.isNotEmpty ? r.nameEn : r.nameAr,
        'name_ar': r.nameAr.isNotEmpty ? r.nameAr : r.nameEn,
        'is_available': r.isAvailable,
        'is_active': true,
        'status': r.status,
        'hourly_rate_single': r.hourlyRateSingle,
        'hourly_rate_multi': r.hourlyRateMulti,
        'max_capacity': r.maxCapacity,
      }).toList();

      final extrasData = state.extras.map((e) => {
        'name': e.nameEn.isNotEmpty ? e.nameEn : e.nameAr,
        'name_ar': e.nameAr.isNotEmpty ? e.nameAr : e.nameEn,
        'price': e.price,
        'category': e.category,
        'is_available': e.isAvailable,
        'is_active': true,
        'stock_quantity': e.stockQuantity,
      }).toList();

      final result = await batchCompleteOnboardingUseCase(
        loungeId: loungeId,
        loungeData: loungeData,
        rooms: roomsData,
        extras: extrasData,
      );

      if (isClosed) return;

      result.fold(
        (failure) => emit(state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage: failure.message,
        )),
        (newLounge) {
          clearDraft();
          emit(state.copyWith(
            status: OnboardingStatus.completed,
            lounge: newLounge,
          ));
        },
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: OnboardingStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
