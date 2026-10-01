import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:play_spot_dashboard/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/entities/onboarding_room_payload.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

class _Remote extends Mock implements OnboardingRemoteDataSource {}

void main() {
  const room = RoomEntity(
    id: 'draft-room',
    loungeId: 'lounge-1',
    nameAr: 'غرفة',
    nameEn: 'Room',
    isAvailable: true,
    images: ['image-1'],
    featuresAr: ['ميزة'],
    featuresEn: ['Feature'],
    hourlyRateSingle: 123.75,
    hourlyRateMulti: 175.5,
    extraControllerPrice: 10,
    maxCapacity: 4,
    controllersCount: 3,
    screenSize: '55',
    spaceTypeId: 'vip_room',
    descriptionAr: 'وصف',
    descriptionEn: 'Description',
  );

  test('onboarding room remains local until atomic final submission', () async {
    final remote = _Remote();
    final result = await OnboardingRepositoryImpl(remote).addRoom(room);
    expect(
      result.getOrElse(() => throw StateError('unexpected failure')),
      room,
    );
    verifyZeroInteractions(remote);
  });

  test('final room payload preserves prices, images and specifications', () {
    final data = OnboardingRoomPayload.fromRoom(room);
    expect(data['hourly_rate_single'], 123.75);
    expect(data['hourly_rate_multi'], 175.5);
    expect(data['extra_controller_price'], 10);
    expect(data['max_capacity'], 4);
    expect(data['controllers_count'], 3);
    expect(data['screen_size'], '55');
    expect(data['space_type_id'], 'vip_room');
    expect(data['images'], ['image-1']);
    expect(data['features_ar'], ['ميزة']);
    expect(data['description_en'], 'Description');
    expect(data['status'], 'available');
    expect(data['id'], room.id);
    expect(data.containsKey('lounge_id'), isFalse);
  });
}
