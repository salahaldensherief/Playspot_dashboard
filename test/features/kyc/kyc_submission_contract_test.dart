import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/kyc/data/datasources/kyc_remote_data_source_impl.dart';

void main() {
  const owner = '00000000-0000-0000-0000-000000000001';
  const lounge = '10000000-0000-0000-0000-000000000001';
  final bytes = Uint8List.fromList([1, 2, 3, 4]);
  Future<SupabaseClient> clientFor(
    Future<http.Response> Function(http.Request) handler,
  ) async {
    final client = SupabaseClient(
      'https://example.invalid',
      'fixture-key',
      httpClient: MockClient(handler),
    );
    addTearDown(client.dispose);
    await client.auth.setInitialSession(
      jsonEncode({
        'access_token': 'fixture-token',
        'token_type': 'bearer',
        'user': {'id': owner},
      }),
    );
    return client;
  }

  http.Response response(
    http.Request request,
    Object body, [
    int status = 200,
  ]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
    request: request,
  );
  Future<void> submit(SupabaseClient client, {String user = owner}) =>
      KycRemoteDataSourceImpl(client).submitKyc(
        userId: user,
        loungeId: lounge,
        idCardBytes: bytes,
        idCardName: 'identity.png',
      );

  test(
    'submission sends exact lounge and stable immutable document path on retry',
    () async {
      final requests = <http.Request>[];
      final client = await clientFor((request) async {
        requests.add(request);
        if (request.url.path.startsWith('/storage/')) {
          if (requests
                  .where((r) => r.url.path.startsWith('/storage/'))
                  .length ==
              2) {
            return response(request, {
              'statusCode': '409',
              'error': 'Duplicate',
              'message': 'Already exists',
            }, 400);
          }
          return response(request, {'Key': 'fixture'});
        }
        return response(request, {
          'success': true,
          'request_id': 'review-1',
          'revision': 1,
          'status': 'pending',
        });
      });
      await submit(client);
      await submit(client);
      final uploads = requests
          .where((r) => r.url.path.startsWith('/storage/'))
          .toList();
      expect(uploads, hasLength(2));
      expect(uploads[0].url, uploads[1].url);
      final path = '$owner/$lounge/id_${sha256.convert(bytes)}.png';
      expect(uploads[0].url.path, endsWith(path));
      expect(uploads[0].headers['x-upsert'], 'false');
      final calls = requests
          .where((r) => r.url.path.startsWith('/rest/'))
          .toList();
      expect(calls, hasLength(2));
      for (final call in calls) {
        expect(call.url.path, '/rest/v1/rpc/submit_lounge_review');
        expect(jsonDecode(call.body), {
          'p_lounge_id': lounge,
          'p_id_document_path': path,
          'p_business_document_path': null,
        });
      }
    },
  );

  test('storage outage is not treated as an existing document', () async {
    final requests = <http.Request>[];
    final client = await clientFor((request) async {
      requests.add(request);
      return response(request, {
        'statusCode': '500',
        'error': 'ServerError',
        'message': 'Unavailable',
      }, 500);
    });
    await expectLater(submit(client), throwsA(isA<StorageException>()));
    expect(requests, hasLength(1));
    expect(requests.single.url.path, startsWith('/storage/'));
  });

  test('foreign owner submission makes no storage or RPC call', () async {
    final requests = <http.Request>[];
    final client = await clientFor((request) async {
      requests.add(request);
      return response(request, {});
    });
    await expectLater(submit(client, user: 'another-owner'), throwsStateError);
    expect(requests, isEmpty);
  });

  test('malformed acknowledgment cannot complete onboarding', () async {
    final client = await clientFor(
      (request) async => response(
        request,
        request.url.path.startsWith('/storage/')
            ? {'Key': 'fixture'}
            : {
                'success': false,
                'request_id': 'review-1',
                'revision': 1,
                'status': 'pending',
              },
      ),
    );
    await expectLater(submit(client), throwsFormatException);
  });
}
