import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/tournaments/data/datasources/tournament_match_remote_helper.dart';

void main() {
  late SupabaseClient client;
  late List<http.Request> requests;
  late Object rpcResponse;
  String? rpcError;
  String? readError;
  String? plainReadError;

  setUp(() {
    requests = [];
    rpcResponse = 1;
    rpcError = readError = plainReadError = null;
    client = SupabaseClient(
      'https://fixture.invalid',
      'fixture-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final isRpc = request.url.path.contains('/rpc/');
        final isJoin =
            request.url.queryParameters['select']?.contains('rooms(') ?? false;
        final error = isRpc ? rpcError : (isJoin ? readError : plainReadError);
        return http.Response(
          jsonEncode(
            error != null
                ? {'code': error, 'message': 'fixture failure'}
                : isRpc
                ? rpcResponse
                : [
                    {
                      'id': 'match-1',
                      'tournament_id': 'tournament-1',
                      'round_number': 1,
                      'status': 'pending',
                    },
                  ],
          ),
          error == null
              ? 200
              : error == '42501'
              ? 403
              : 400,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
  });
  tearDown(() => client.dispose());

  test(
    'a denied draw must not report old matches as a successful bracket',
    () async {
      rpcError = '42501';
      await expectLater(
        TournamentMatchRemoteHelper(client).drawBracket('tournament-1'),
        throwsA(isA<PostgrestException>()),
      );
      expect(requests, hasLength(1));
    },
  );

  test(
    'the deployed integer draw response fetches the created matches',
    () async {
      final matches = await TournamentMatchRemoteHelper(
        client,
      ).drawBracket('tournament-1');
      expect(matches.single.id, 'match-1');
      expect(requests, hasLength(2));
      expect(jsonDecode(requests.first.body), {
        'p_tournament_id': 'tournament-1',
      });
    },
  );

  test(
    'match authorization failure stays visible without a weaker fallback',
    () async {
      readError = '42501';
      await expectLater(
        TournamentMatchRemoteHelper(client).getMatches('tournament-1'),
        throwsA(isA<PostgrestException>()),
      );
      expect(requests, hasLength(1));
    },
  );

  test(
    'a missing join relationship can use the compatible plain query',
    () async {
      readError = 'PGRST200';
      final matches = await TournamentMatchRemoteHelper(
        client,
      ).getMatches('tournament-1');
      expect(matches.single.id, 'match-1');
      expect(requests, hasLength(2));
    },
  );

  test(
    'failure of the compatibility query is not an empty tournament',
    () async {
      readError = 'PGRST200';
      plainReadError = '42501';
      await expectLater(
        TournamentMatchRemoteHelper(client).getMatches('tournament-1'),
        throwsA(isA<PostgrestException>()),
      );
    },
  );

  test('a malformed draw response does not silently become success', () async {
    rpcResponse = {'success': false, 'error': 'invalid_state'};
    await expectLater(
      TournamentMatchRemoteHelper(client).drawBracket('tournament-1'),
      throwsA(isA<FormatException>()),
    );
    expect(requests, hasLength(1));
  });
}
