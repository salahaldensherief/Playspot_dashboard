import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/services/local_cache_service.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/entities/lounge_draft_params.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/entities/saved_onboarding_draft.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/usecases/add_extra_usecase.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/usecases/add_room_usecase.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/usecases/batch_complete_onboarding_usecase.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/usecases/get_saved_onboarding_draft_usecase.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_state.dart';

class _Repository extends Mock implements OnboardingRepository {}

class _Cache extends Mock implements LocalCacheService {}

class _Location extends Mock implements LocationService {}

void main() {
  const lounge = Lounge(
    id: 'lounge-1',
    name: 'Saved',
    imageUrl: 'https://example.invalid/saved.jpg',
    opensAt: '10:00',
    closesAt: '02:00',
    status: 'rejected',
  );
  const saved = SavedOnboardingDraft(
    lounge: lounge,
    fields: LoungeDraftParams(name: 'Saved', contactPhone: '01000000000'),
    rooms: [
      RoomEntity(
        id: 'stable-room',
        loungeId: 'lounge-1',
        nameAr: 'غرفة',
        nameEn: 'Room',
        isAvailable: true,
        images: [],
        featuresAr: [],
        featuresEn: [],
      ),
    ],
    extras: [],
    reviewNotes: 'Clarify address',
  );
  late _Repository repository;
  late _Cache cache;
  late OnboardingCubit cubit;
  setUp(() {
    repository = _Repository();
    cache = _Cache();
    when(() => cache.setJson(any(), any())).thenAnswer((_) async {});
    when(() => cache.remove(any())).thenAnswer((_) async {});
    cubit = OnboardingCubit(
      addRoomUseCase: AddRoomUseCase(repository),
      addExtraUseCase: AddExtraUseCase(repository),
      batchCompleteOnboardingUseCase: BatchCompleteOnboardingUseCase(
        repository,
      ),
      getSavedDraftUseCase: GetSavedOnboardingDraftUseCase(repository),
      locationService: _Location(),
      localCacheService: cache,
    );
    cubit.restoreDraft(ownerId: 'owner-1', loungeId: 'lounge-1');
  });
  tearDown(() => cubit.close());
  test(
    'owner and lounge draft scopes cannot expose the previous cached draft',
    () {
      when(
        () => cache.getJson('cache_onboarding_v2_owner-1_lounge-1'),
      ).thenReturn({'name': 'Owner A draft'});
      cubit.restoreDraft(ownerId: 'owner-1', loungeId: 'lounge-1');
      expect(cubit.state.draft.name, 'Owner A draft');
      cubit.restoreDraft(ownerId: 'owner-2', loungeId: 'lounge-2');
      expect(cubit.state.draft.name, isEmpty);
      expect(cubit.state.rooms, isEmpty);
      verifyNever(() => cache.getJson('cache_onboarding_lounge_draft_v1'));
    },
  );
  test('a late server draft cannot overwrite another owner scope', () async {
    final pending = Completer<Either<Failure, SavedOnboardingDraft>>();
    when(
      () => repository.getSavedDraft('lounge-1'),
    ).thenAnswer((_) => pending.future);
    final operation = cubit.restoreSavedDraft('lounge-1');
    cubit.restoreDraft(ownerId: 'owner-2', loungeId: 'lounge-2');
    pending.complete(const Right(saved));
    await operation;
    expect(cubit.state.draft.name, isEmpty);
    expect(cubit.state.rooms, isEmpty);
    expect(cubit.state.status, OnboardingStatus.initial);
  });
  test(
    'restoration retains photos, resource IDs and rejection reason',
    () async {
      when(
        () => repository.getSavedDraft('lounge-1'),
      ).thenAnswer((_) async => const Right(saved));
      await cubit.restoreSavedDraft('lounge-1');
      expect(cubit.state.status, OnboardingStatus.restored);
      expect(cubit.state.rooms.single.id, 'stable-room');
      expect(cubit.state.lounge!.imageUrl, lounge.imageUrl);
      expect(cubit.state.reviewNotes, 'Clarify address');
      expect(cubit.state.draft.name, 'Saved');
    },
  );
  test('restoration preserves unsaved local field edits', () async {
    cubit.saveDraft(const LoungeDraftParams(name: 'Local correction'));
    when(
      () => repository.getSavedDraft('lounge-1'),
    ).thenAnswer((_) async => const Right(saved));
    await cubit.restoreSavedDraft('lounge-1');
    expect(cubit.state.draft.name, 'Local correction');
    expect(cubit.state.rooms.single.id, 'stable-room');
  });
  test(
    'failed restore keeps local draft and cannot mark submission complete',
    () async {
      cubit.saveDraft(const LoungeDraftParams(name: 'Local correction'));
      when(
        () => repository.getSavedDraft('lounge-1'),
      ).thenAnswer((_) async => const Left(ServerFailure('offline')));
      await cubit.restoreSavedDraft('lounge-1');
      cubit.markReviewSubmitted();
      expect(cubit.state.status, OnboardingStatus.failure);
      expect(cubit.state.draft.name, 'Local correction');
      verifyNever(() => cache.remove(any()));
    },
  );
  test(
    'saving venue details waits for final review acknowledgment before completing',
    () async {
      when(
        () => repository.getSavedDraft('lounge-1'),
      ).thenAnswer((_) async => const Right(saved));
      when(
        () => repository.batchCompleteOnboarding(
          loungeId: 'lounge-1',
          loungeData: any(named: 'loungeData'),
          rooms: any(named: 'rooms'),
          extras: any(named: 'extras'),
        ),
      ).thenAnswer((_) async => const Right(lounge));
      await cubit.restoreSavedDraft('lounge-1');
      await cubit.submitLounge(lounge: lounge, loungeId: 'lounge-1');
      expect(cubit.state.status, OnboardingStatus.saved);
      verifyNever(() => cache.remove(any()));
      cubit.markReviewSubmitted();
      expect(cubit.state.status, OnboardingStatus.completed);
      verify(() => cache.remove(any())).called(1);
    },
  );
  test('closing while restore is pending ignores the late response', () async {
    final pending = Completer<Either<Failure, SavedOnboardingDraft>>();
    when(
      () => repository.getSavedDraft('lounge-1'),
    ).thenAnswer((_) => pending.future);
    final future = cubit.restoreSavedDraft('lounge-1');
    await cubit.close();
    pending.complete(const Right(saved));
    await future;
    expect(cubit.state.status, OnboardingStatus.loading);
  });
}
