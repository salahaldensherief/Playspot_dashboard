import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads tournament-scoped display names without querying private profiles.
Future<Map<String, String>> fetchTournamentParticipantNames(
  SupabaseClient client,
  String tournamentId,
) async {
  final response = await client.rpc(
    'get_tournament_participant_names',
    params: {'p_tournament_id': tournamentId},
  );
  if (response is! List) {
    throw const FormatException(
      'Invalid tournament participant names response',
    );
  }
  final names = <String, String>{};
  for (final row in response) {
    if (row is! Map || row['participant_id'] is! String) {
      throw const FormatException('Invalid tournament participant name');
    }
    final name = (row['user_name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) {
      names[row['participant_id'] as String] = name;
    }
  }
  return names;
}
