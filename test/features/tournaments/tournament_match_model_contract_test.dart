import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/tournaments/data/models/tournament_match_model.dart';

void main() {
  test('bronze remains distinct from the championship final', () {
    final bronze = TournamentMatchModel.fromJson({'match_type': 'third_place'});
    final legacy = TournamentMatchModel.fromJson({});
    expect(bronze.isThirdPlace, isTrue);
    expect(legacy.isThirdPlace, isFalse);
    expect(bronze, isNot(legacy));
  });
  test('deployed match fields retain order, scores and evidence', () {
    final match = TournamentMatchModel.fromJson({
      'id': 'match-1',
      'tournament_id': 'tournament-1',
      'round_number': 2,
      'match_order': 3,
      'score_player1': 4,
      'score_player2': 2,
      'proof_image_url': 'https://fixture.invalid/evidence.png',
      'status': 'completed',
    });
    expect(match.matchNumber, 3);
    expect(match.player1Score, 4);
    expect(match.player2Score, 2);
    expect(match.proofUrl, 'https://fixture.invalid/evidence.png');
  });

  for (final status in [
    'pending_confirmation',
    'cancelled',
    'walkover',
    'no_show',
  ]) {
    test('$status is not a scheduled match with an available start action', () {
      final match = TournamentMatchModel.fromJson({'status': status});
      expect(match.isScheduled, isFalse);
      expect(match.status.toDbString(), status);
    });
  }

  test('a walkover is a finished bye in the bracket', () {
    final match = TournamentMatchModel.fromJson({'status': 'walkover'});
    expect(match.isBye, isTrue);
    expect(match.isCompleted, isTrue);
  });

  test('unknown backend states never expose the start action', () {
    final match = TournamentMatchModel.fromJson({'status': 'future_state'});
    expect(match.isScheduled, isFalse);
  });

  test('legacy field aliases remain readable', () {
    final match = TournamentMatchModel.fromJson({
      'match_number': 2,
      'player1_score': 3,
      'player2_score': 1,
      'proof_url': 'legacy-proof',
      'status': 'scheduled',
    });
    expect(match.matchNumber, 2);
    expect(match.player1Score, 3);
    expect(match.player2Score, 1);
    expect(match.proofUrl, 'legacy-proof');
    expect(match.isScheduled, isTrue);
  });
}
