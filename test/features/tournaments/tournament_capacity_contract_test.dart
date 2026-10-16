import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/tournaments/data/models/tournament_model.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_entity.dart';

void main() {
  test(
    'capacity counts active seats rather than waitlist or terminal entries',
    () {
      final t = TournamentModel.fromJson({
        'tournament_participants': [
          for (final status in [
            'pending_payment',
            'confirmed',
            'checked_in',
            'waitlist',
            'withdrawn',
            'expired',
            'cancelled',
            'eliminated',
            'no_show',
            'future_unknown',
          ])
            {'id': status, 'registration_status': status},
        ],
      });
      expect(t.registeredCount, 3);
    },
  );
  test('authoritative count and legacy id-only joins remain readable', () {
    expect(
      TournamentModel.fromJson({'registered_count': 7}).registeredCount,
      7,
    );
    expect(
      TournamentModel.fromJson({
        'tournament_participants': [
          {'id': 'p1'},
          {'id': 'p2'},
        ],
      }).registeredCount,
      2,
    );
  });
  for (final status in TournamentStatus.values) {
    test('draw action agrees with the deployed allowed phase $status', () {
      final t = TournamentModel.fromJson({
        'status': status.toDbString(),
        'registered_count': 2,
      });
      expect(t.minPlayers, 2);
      expect(
        t.canDrawBracket,
        status == TournamentStatus.registrationClosed ||
            status == TournamentStatus.checkInClosed,
      );
    });
  }
}
