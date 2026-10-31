import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/services/local_cache_service.dart';
import 'package:play_spot_dashboard/features/rooms/data/datasources/room_remote_data_source.dart';
import 'package:play_spot_dashboard/features/rooms/data/repositories/room_repository_impl.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_realtime_datasource.dart';
import 'package:play_spot_dashboard/features/bookings/data/repositories/booking_repository_impl.dart';

class _Rooms extends Mock implements RoomRemoteDataSource {}

class _Cache extends Mock implements LocalCacheService {}

class _Bookings extends Mock implements BookingRemoteDataSource {}

class _Realtime extends Mock implements BookingRealtimeDataSource {}

void main() {
  for (final row in [
    ['55000', 'ROOM_HAS_ACTIVE_SESSION', 'room_has_active_session'],
    ['42501', 'NOT_AUTHORIZED', 'room_operation_permission_denied'],
    ['XX000', 'private database detail', 'room_operation_failed'],
  ]) {
    test(
      'room status denial ${row[0]} stays failure with safe UI key',
      () async {
        final source = _Rooms();
        final cache = _Cache();
        when(
          () => source.updateRoomStatus('room', 'available'),
        ).thenThrow(PostgrestException(code: row[0], message: row[1]));
        final result = await RoomRepositoryImpl(
          source,
          cache,
        ).updateRoomStatus('room', RoomStatusEnum.available);
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure.message, row[2]),
          (_) => fail('Denied status became success'),
        );
        verifyNever(() => cache.getJson(any()));
      },
    );
  }
  for (final code in [
    'ROOM_HAS_ACTIVE_SESSION',
    'ROOM_NOT_AVAILABLE_FOR_SESSION',
  ]) {
    test('session start maps $code without exposing database detail', () async {
      final source = _Bookings();
      when(
        () => source.startBookingSession('booking'),
      ).thenThrow(PostgrestException(code: '55000', message: code));
      final result = await BookingRepositoryImpl(
        source,
        _Realtime(),
      ).startBookingSession('booking');
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, code.toLowerCase()),
        (_) => fail('Denied start became success'),
      );
    });
  }
}
