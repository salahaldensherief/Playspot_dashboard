import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/audit/data/datasources/audit_remote_datasource.dart';
import 'package:play_spot_dashboard/features/audit/data/models/audit_log_model.dart';
import 'package:play_spot_dashboard/features/audit/domain/usecases/get_audit_logs_usecase.dart';
import 'package:play_spot_dashboard/features/audit/domain/usecases/get_timeline_logs_usecase.dart';
import 'package:play_spot_dashboard/features/audit/domain/usecases/export_audit_logs_csv_usecase.dart';

void main() {
  test('CSV continues past a full batch using the stable cursor', () async {
    final calls = <Map<String, dynamic>>[];
    final client = SupabaseClient(
      'https://example.invalid',
      'fixture',
      httpClient: MockClient((request) async {
        calls.add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));
        final count = calls.length == 1 ? 5000 : 1;
        return http.Response(
          jsonEncode(
            List.generate(
              count,
              (i) => {
                'id': calls.length == 1 ? 'room:$i' : 'room:older',
                'entity_type': 'room',
                'action': 'update',
                'created_at': '2026-10-04T12:00:00Z',
              },
            ),
          ),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    final csv = await AuditRemoteDataSourceImpl(client).exportAuditLogsCsv(
      const ExportAuditLogsParams(loungeId: 'venue', entityType: 'room'),
    );
    expect(calls, hasLength(2));
    expect(calls.last['p_last_id'], 'room:4999');
    expect(calls.last['p_last_created_at'], '2026-10-04T12:00:00.000Z');
    expect(calls.last['p_entity_type'], 'room');
    expect(csv.split('\n'), hasLength(5003));
    expect(csv, contains('"room:older"'));
  });
  for (final operation in ['list', 'booking', 'export']) {
    for (final code in ['42501', 'PGRST202']) {
      test(
        '$operation surfaces $code without a fallback or fabricated empty export',
        () async {
          final calls = <http.Request>[];
          final client = SupabaseClient(
            'https://example.invalid',
            'fixture',
            httpClient: MockClient((request) async {
              calls.add(request);
              return http.Response(
                jsonEncode({'code': code, 'message': 'private detail'}),
                403,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }),
          );
          addTearDown(client.dispose);
          final source = AuditRemoteDataSourceImpl(client);
          final Future<Object> future = switch (operation) {
            'booking' => source.getTimelineLogs(
              const GetTimelineLogsParams(
                loungeId: 'venue',
                entityType: 'booking',
                entityId: 'booking',
              ),
            ),
            'export' => source.exportAuditLogsCsv(
              const ExportAuditLogsParams(loungeId: 'venue'),
            ),
            _ => source.getAuditLogs(
              const GetAuditLogsParams(loungeId: 'venue'),
            ),
          };
          await expectLater(future, throwsA(isA<PostgrestException>()));
          expect(calls, hasLength(1));
          expect(calls.single.url.path, '/rest/v1/rpc/get_audit_logs');
          final body = jsonDecode(calls.single.body);
          expect(body['p_lounge_id'], 'venue');
          if (operation == 'booking') {
            expect(body['p_booking_id'], 'booking');
            expect(body.containsKey('p_entity_id'), isFalse);
          }
        },
      );
    }
  }
  test('global scope and both cursor components are preserved', () async {
    late http.Request call;
    final client = SupabaseClient(
      'https://example.invalid',
      'fixture',
      httpClient: MockClient((request) async {
        call = request;
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    final stamp = DateTime.utc(2026, 10, 4);
    await AuditRemoteDataSourceImpl(client).getAuditLogs(
      GetAuditLogsParams(
        loungeId: '',
        lastId: 'room:event',
        lastCreatedAt: stamp,
      ),
    );
    final body = jsonDecode(call.body);
    expect(body['p_lounge_id'], isNull);
    expect(body['p_last_id'], 'room:event');
    expect(body['p_last_created_at'], stamp.toIso8601String());
  });
  test(
    'CSV retains quotes and multiline reasons while treating formula-like text as text',
    () async {
      final client = SupabaseClient(
        'https://example.invalid',
        'fixture',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode([
              {
                'id': 'room:event',
                'entity_type': 'room',
                'entity_id': 'room',
                'action': 'update',
                'created_at': '2026-10-04T12:00:00Z',
                'actor_name': '=SUM(1,2)',
                'reason': 'Comma, "quoted"\nsecond line',
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          ),
        ),
      );
      addTearDown(client.dispose);
      final csv = await AuditRemoteDataSourceImpl(
        client,
      ).exportAuditLogsCsv(const ExportAuditLogsParams(loungeId: 'venue'));
      expect(csv, contains('"\'=SUM(1,2)"'));
      expect(csv, contains('"Comma, ""quoted""\nsecond line"'));
    },
  );
  for (final data in [
    {'id': 'event'},
    {'created_at': '2026-10-04T12:00:00Z'},
    {'id': 'event', 'created_at': 'bad-date'},
  ]) {
    test('invalid audit identity/timestamp is rejected: $data', () {
      expect(() => AuditLogModel.fromJson(data), throwsFormatException);
    });
  }
}
