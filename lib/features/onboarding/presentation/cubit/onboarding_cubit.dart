import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_multi_image_picker.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import '../../../lounges/domain/entities/extra_entity.dart';
import '../../../lounges/domain/entities/lounge.dart';
import '../../../rooms/domain/entities/room_entity.dart';
import '../../domain/usecases/add_extra_usecase.dart';
import '../../domain/usecases/add_room_usecase.dart';
import '../../domain/usecases/setup_lounge_usecase.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final AddRoomUseCase addRoomUseCase;
  final AddExtraUseCase addExtraUseCase;
  final SetupLoungeUseCase setupLoungeUseCase;
  final LocationService locationService;

  OnboardingCubit({
    required this.addRoomUseCase,
    required this.addExtraUseCase,
    required this.setupLoungeUseCase,
    required this.locationService,
  }) : super(const OnboardingState());

  void nextStep() {
    if (state.currentStep < 4) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
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

      final position = await locationService.getCurrentPosition();
      String? cityName;
      if (position != null && context != null && context.mounted) {
        cityName = await locationService.getCityFromPosition(position, context);
      }

      final result = await setupLoungeUseCase(lounge.copyWith(
        id: loungeId,
        imageUrl: mainImageUrl,
        images: galleryUrls,
        lat: position?.latitude,
        lng: position?.longitude,
        city: cityName ?? lounge.city,
      ));

      if (isClosed) return;

      result.fold(
        (failure) => emit(state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage: failure.message,
        )),
        (newLounge) => emit(state.copyWith(
          status: OnboardingStatus.success,
          lounge: newLounge,
        )),
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
