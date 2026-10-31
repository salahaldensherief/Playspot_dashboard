import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/lounges/data/datasources/lounge_query_remote_helper.dart';
import 'package:play_spot_dashboard/features/lounges/data/models/lounge_model.dart';

void main() {
  late SupabaseClient client;
  late List<http.Request> requests;
  late List<Map<String, dynamic>> venues;
  late List<Map<String, dynamic>> rooms;
  var loungeStatus = 200;
  var roomStatus = 200;
  setUp(() {
    requests = [];
    loungeStatus = roomStatus = 200;
    venues = [
      {
        'id': 'active',
        'owner_id': 'owner-1',
        'status': 'active',
        'is_active': true,
        'is_open': false,
      },
      {
        'id': 'pending',
        'status': 'pending',
        'is_active': false,
        'is_open': false,
      },
      {'id': 'suspended', 'status': 'suspended', 'is_active': false},
      {'id': 'deleted', 'status': 'deleted'},
    ];
    rooms = [
      {'id': 'r1', 'lounge_id': 'active', 'status': 'available'},
      {'id': 'r2', 'lounge_id': 'active', 'status': 'maintenance'},
      {'id': 'r3', 'lounge_id': 'active', 'status': 'deleted'},
      {'id': 'r4', 'lounge_id': 'pending', 'status': null},
    ];
    client = SupabaseClient(
      'https://fixture.invalid',
      'fixture-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        final status = path.endsWith('/lounges')
            ? loungeStatus
            : path.endsWith('/rooms')
            ? roomStatus
            : 200;
        Object data;
        if (status != 200) {
          data = {'code': '42501', 'message': 'fixture permission denied'};
        } else if (path.endsWith('/lounges')) {
          data = venues;
        } else if (path.endsWith('/rooms')) {
          final offset = int.parse(
            request.url.queryParameters['offset'] ?? '0',
          );
          data = rooms.skip(offset).take(1000).toList();
        } else if (path.endsWith('/profiles')) {
          data = [
            {
              'id': 'owner-1',
              'full_name': 'Owner',
              'email': 'owner@example.invalid',
            },
          ];
        } else {
          fail('Unexpected request: $path');
        }
        return http.Response(
          jsonEncode(data),
          status,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
  });
  tearDown(() => client.dispose());
  Future<List<LoungeModel>> load() =>
      LoungeQueryRemoteHelper(client).getLounges();

  test(
    'management retains pending and suspended venues and counts non-deleted rooms',
    () async {
      final data = await load();
      expect(data.map((e) => e.id), ['active', 'pending', 'suspended']);
      expect(data.map((e) => e.availableRooms), [2, 1, 0]);
      expect(data.first.ownerName, 'Owner');
      expect(data.first.isOpen, isFalse);
      expect(data.first.isActive, isTrue);
      final ownerRequest = requests.singleWhere(
        (r) => r.url.path.endsWith('/profiles'),
      );
      expect(ownerRequest.url.queryParameters['id'], 'in.("owner-1")');
      expect(requests.every((r) => r.method == 'GET'), isTrue);
    },
  );
  test('room totals continue beyond the API page limit', () async {
    rooms = List.generate(
      1001,
      (i) => {'id': 'r$i', 'lounge_id': 'active', 'status': 'available'},
    );
    expect((await load()).first.availableRooms, 1001);
    expect(requests.where((r) => r.url.path.endsWith('/rooms')), hasLength(2));
  });
  test(
    'denied lounge read stays an error without discovery or revenue fallback',
    () async {
      loungeStatus = 403;
      await expectLater(
        load(),
        throwsA(
          isA<PostgrestException>().having((e) => e.code, 'code', '42501'),
        ),
      );
      expect(requests, hasLength(1));
    },
  );
  test('denied room count never displays a successful zero count', () async {
    roomStatus = 403;
    await expectLater(load(), throwsA(isA<PostgrestException>()));
    expect(requests, hasLength(2));
  });
  test('empty management list makes no dependent requests', () async {
    venues = [];
    expect(await load(), isEmpty);
    expect(requests, hasLength(1));
  });
  test(
    'missing room count remains unknown in models used outside management',
    () {
      expect(LoungeModel.fromJson({'id': 'venue'}).availableRooms, isNull);
      expect(
        LoungeModel.fromJson({'id': 'venue', 'rooms_count': 0}).availableRooms,
        0,
      );
    },
  );
}
