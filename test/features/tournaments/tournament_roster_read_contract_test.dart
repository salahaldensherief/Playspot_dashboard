import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/tournaments/data/datasources/tournament_match_remote_helper.dart';
import 'package:play_spot_dashboard/features/tournaments/data/datasources/tournament_participant_remote_helper.dart';

void main() {
  late SupabaseClient client;
  late List<http.Request> requests;
  var rosterDenied = false;
  setUp(() {
    rosterDenied = false;
    requests = [];
    client = SupabaseClient(
      'https://fixture.invalid',
      'fixture-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final isRoster = request.url.path.endsWith(
          '/get_tournament_participant_names',
        );
        final Object body = isRoster
            ? rosterDenied
                  ? {'code': '42501', 'message': 'denied'}
                  : [
                      {
                        'participant_id': 'p1',
                        'user_id': 'u1',
                        'user_name': 'Player Alpha',
                      },
                      {
                        'participant_id': 'p2',
                        'user_id': 'u2',
                        'user_name': 'Player Bravo',
                      },
                    ]
            : request.url.path.endsWith('/tournament_matches')
            ? [
                {
                  'id': 'm1',
                  'tournament_id': 't1',
                  'round_number': 1,
                  'match_order': 1,
                  'player1_id': 'p1',
                  'player2_id': 'p2',
                  'status': 'completed',
                  'score_player1': 3,
                  'score_player2': 1,
                },
              ]
            : [
                {
                  'id': 'p1',
                  'tournament_id': 't1',
                  'user_id': 'u1',
                  'payment_status': 'paid',
                  'registration_status': 'checked_in',
                  'is_checked_in': true,
                },
                {
                  'id': 'p2',
                  'tournament_id': 't1',
                  'user_id': 'u2',
                  'payment_status': 'paid',
                  'registration_status': 'checked_in',
                  'is_checked_in': true,
                },
              ];
        return http.Response(
          jsonEncode(body),
          isRoster && rosterDenied ? 403 : 200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
  });
  tearDown(() => client.dispose());
  test(
    'roster uses scoped display names without broad profile reads',
    () async {
      final rows = await TournamentParticipantRemoteHelper(
        client,
      ).getParticipants('t1');
      expect(rows.map((p) => p.userName), ['Player Alpha', 'Player Bravo']);
      expect(rows.every((p) => p.isPaymentApproved), isTrue);
      expect(requests, hasLength(2));
      expect(requests.any((r) => r.url.path.endsWith('/profiles')), isFalse);
      expect(jsonDecode(requests.last.body), {'p_tournament_id': 't1'});
    },
  );
  test(
    'bracket maps participant identities to names and requests stable match order',
    () async {
      final rows = await TournamentMatchRemoteHelper(client).getMatches('t1');
      expect(rows.single.player1Name, 'Player Alpha');
      expect(rows.single.player2Name, 'Player Bravo');
      expect(
        requests.first.url.queryParameters['order'],
        'round_number.asc.nullslast,match_order.asc.nullslast',
      );
      expect(requests, hasLength(2));
    },
  );
  test('a denied roster is an error, not an empty participant list', () async {
    rosterDenied = true;
    await expectLater(
      TournamentParticipantRemoteHelper(client).getParticipants('t1'),
      throwsA(isA<PostgrestException>()),
    );
  });
}
