import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/services/local_cache_service.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/rooms/data/datasources/room_remote_data_source.dart';
import 'package:play_spot_dashboard/features/rooms/data/models/room_model.dart';
import 'package:play_spot_dashboard/features/rooms/data/models/room_space_type_model.dart';
import 'package:play_spot_dashboard/features/rooms/data/repositories/room_repository_impl.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_space_type.dart';
import 'package:play_spot_dashboard/features/rooms/domain/repositories/room_repository.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';

class _Source extends Mock implements RoomRemoteDataSource {}

class _Cache extends Mock implements LocalCacheService {}

class _Repository extends Mock implements RoomRepository {}

const catalogId = '00000000-0000-0000-0000-000000000123';
const type = RoomSpaceTypeModel(
  id: catalogId,
  name: 'open_area',
  label: 'Open area',
);

void main() {
  test(
    'room join preserves the catalog UUID and canonical name across cache',
    () {
      final room = RoomModel.fromJson({
        'id': 'room',
        'lounge_id': 'venue',
        'space_type_id': catalogId,
        'space_types': {'name': 'open_area', 'label': 'Open area'},
      });
      expect(room.spaceTypeId, catalogId);
      expect(room.isOpenArea, isTrue);
      final restored = RoomModel.fromJson(room.toCacheJson());
      expect(restored.spaceTypeId, catalogId);
      expect(restored.isOpenArea, isTrue);
      expect(room.toJson()['space_type_id'], catalogId);
      expect(room.toJson().containsKey('space_type_name'), isFalse);
      expect(room.toJson().containsKey('space_types'), isFalse);
    },
  );
  test('legacy catalog names group without changing their IDs', () {
    expect(roomSpaceTypeKey('open'), 'open_area');
    expect(roomSpaceTypeKey('private'), 'standard_room');
    expect(roomSpaceTypeKey('vip'), 'vip_room');
    expect(type.id, catalogId);
  });
  test('catalog and joined room reads use real backend columns', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://fixture.invalid',
      'fixture-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(
            request.url.path.endsWith('/space_types')
                ? [type.toJson()]
                : [
                    {
                      'id': 'room',
                      'lounge_id': 'venue',
                      'space_type_id': catalogId,
                      'space_types': {'name': 'open_area', 'label': 'Open'},
                    },
                  ],
          ),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    final source = RoomRemoteDataSourceImpl(client);
    expect((await source.getSpaceTypes()).single.id, catalogId);
    expect((await source.getRooms('venue')).single.isOpenArea, isTrue);
    expect(requests.first.url.queryParameters['select'], 'id,name,label');
    expect(
      requests.last.url.queryParameters['select'],
      contains('space_types(name,label)'),
    );
  });
  test(
    'offline catalog uses valid cache, but permission denial remains failure',
    () async {
      final source = _Source();
      final cache = _Cache();
      when(
        () => cache.getJson('cache_room_space_types'),
      ).thenReturn([type.toJson()]);
      when(source.getSpaceTypes).thenThrow(http.ClientException('offline'));
      final repository = RoomRepositoryImpl(source, cache);
      (await repository.getSpaceTypes()).fold(
        (_) => fail('Valid offline catalog must be readable'),
        (types) => expect(types, [type]),
      );
      when(
        source.getSpaceTypes,
      ).thenThrow(const PostgrestException(message: 'denied', code: '42501'));
      expect(await repository.getSpaceTypes(), isA<Left>());
    },
  );
  test('malformed offline cache remains a failure', () async {
    final source = _Source();
    final cache = _Cache();
    when(source.getSpaceTypes).thenThrow(http.ClientException('offline'));
    when(() => cache.getJson('cache_room_space_types')).thenReturn([
      {'name': 'open_area'},
    ]);
    expect(
      await RoomRepositoryImpl(source, cache).getSpaceTypes(),
      isA<Left>(),
    );
  });
  test('catalog response after cubit close does not emit', () async {
    final repository = _Repository();
    final response = Completer<Either<Failure, List<RoomSpaceType>>>();
    when(repository.getSpaceTypes).thenAnswer((_) => response.future);
    final cubit = RoomCubit(repository);
    final pending = cubit.loadSpaceTypes();
    expect(cubit.state.spaceTypesStatus, RoomStatus.loading);
    await cubit.close();
    response.complete(const Right([type]));
    await pending;
    expect(cubit.state.spaceTypesStatus, RoomStatus.loading);
  });
}
