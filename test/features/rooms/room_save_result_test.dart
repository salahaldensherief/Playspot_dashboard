import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/domain/repositories/room_repository.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';

class MockRoomRepository extends Mock implements RoomRepository {}
void main() {
  const room = RoomEntity(id: 'room', loungeId: 'lounge', nameAr: 'غرفة',
    nameEn: 'Room', isAvailable: true, images: [], featuresAr: [], featuresEn: []);
  test('failed create keeps the dialog open through an explicit false result', () async {
    final repository = MockRoomRepository();
    when(() => repository.addRoom(room)).thenAnswer((_) async => const Left(ServerFailure('permission denied')));
    final cubit = RoomCubit(repository);
    expect(await cubit.addNewRoom(room), isFalse);
    expect(cubit.state.status, RoomStatus.failure);
    await cubit.close();
  });
  test('failed update reports failure rather than successful completion', () async {
    final repository = MockRoomRepository();
    when(() => repository.updateRoom(room)).thenAnswer((_) async => const Left(ServerFailure('connection failed')));
    final cubit = RoomCubit(repository);
    expect(await cubit.updateRoom(room), isFalse);
    expect(cubit.state.errorMessage, 'connection failed');
    await cubit.close();
  });
  test('successful update exits loading even without an active room watcher', () async {
    final repository = MockRoomRepository();
    when(() => repository.updateRoom(room)).thenAnswer((_) async => const Right(null));
    final cubit = RoomCubit(repository);
    expect(await cubit.updateRoom(room), isTrue);
    expect(cubit.state.status, RoomStatus.success);
    await cubit.close();
  });
}
