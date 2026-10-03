import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/audit/data/datasources/audit_remote_datasource.dart';
import 'package:play_spot_dashboard/features/audit/data/repositories/audit_repository_impl.dart';
import 'package:play_spot_dashboard/features/audit/domain/usecases/get_timeline_logs_usecase.dart';

void main() {
  const params = GetTimelineLogsParams(
    loungeId: 'venue',
    entityType: 'room',
    entityId: 'room',
    limit: 20,
  );
  test(
    'room timeline reads the real scoped status audit and maps changes',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://fixture.invalid',
        'fixture-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode([
              {
                'id': 'event',
                'room_id': 'room',
                'lounge_id': 'venue',
                'changed_by': 'operator',
                'operation': 'UPDATE',
                'old_status': 'available',
                'new_status': 'maintenance',
                'old_is_available': true,
                'new_is_available': false,
                'changed_at': '2026-10-04T08:15:00Z',
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final logs = await AuditRemoteDataSourceImpl(
        client,
      ).getTimelineLogs(params);
      final request = requests.single;
      expect(request.url.path, '/rest/v1/room_status_audit');
      expect(request.url.queryParameters['room_id'], 'eq.room');
      expect(request.url.queryParameters['lounge_id'], 'eq.venue');
      expect(request.url.queryParameters['order'], 'changed_at.desc.nullslast');
      expect(request.url.queryParameters['limit'], '20');
      expect(
        request.url.queryParameters['select'],
        contains('old_status,new_status'),
      );
      final event = logs.single;
      expect(event.entityType, 'room');
      expect(event.entityId, 'room');
      expect(event.loungeId, 'venue');
      expect(event.actorUserId, 'operator');
      expect(event.createdAt, DateTime.utc(2026, 10, 4, 8, 15));
      expect(event.oldData, {'status': 'available', 'is_available': true});
      expect(event.newData, {'status': 'maintenance', 'is_available': false});
      expect(event.changes.length, 2);
    },
  );
  test(
    'room audit authorization failure remains failure without fallback',
    () async {
      var requests = 0;
      final client = SupabaseClient(
        'https://fixture.invalid',
        'fixture-key',
        httpClient: MockClient((request) async {
          requests++;
          return http.Response(
            jsonEncode({'code': '42501', 'message': 'permission denied'}),
            403,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final repository = AuditRepositoryImpl(AuditRemoteDataSourceImpl(client));
      final result = await repository.getTimelineLogs(params);
      expect(result.isLeft(), isTrue);
      expect(requests, 1);
    },
  );
  test('room audit refuses unscoped reads before sending a request', () async {
    var requests = 0;
    final client = SupabaseClient(
      'https://fixture.invalid',
      'fixture-key',
      httpClient: MockClient((request) async {
        requests++;
        return http.Response('[]', 200, request: request);
      }),
    );
    addTearDown(client.dispose);
    final source = AuditRemoteDataSourceImpl(client);
    await expectLater(
      source.getTimelineLogs(
        const GetTimelineLogsParams(
          loungeId: '',
          entityType: 'room',
          entityId: 'room',
        ),
      ),
      throwsArgumentError,
    );
    expect(requests, 0);
  });
}
