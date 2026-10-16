import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/tournaments/data/models/tournament_participant_model.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_participant_entity.dart';

void main() {
  test('a paid checked-in participant is not an unpaid payment candidate', () {
    final p = TournamentParticipantModel.fromJson({
      'payment_status': 'paid',
      'registration_status': 'checked_in',
      'is_checked_in': true,
    });
    expect(p.isPaymentApproved, isTrue);
    expect(p.participantStatus.toDbString(), 'checked_in');
    expect(p.canRecordCash, isFalse);
  });
  for (final status in [
    'pending_payment',
    'waitlist',
    'confirmed',
    'checked_in',
    'eliminated',
    'expired',
    'cancelled',
    'withdrawn',
    'no_show',
  ]) {
    test(
      'registration status $status retains the deployed lifecycle value',
      () {
        expect(ParticipantStatus.fromString(status).toDbString(), status);
      },
    );
  }
  test('only unpaid seat holders are eligible for cash collection', () {
    final p = TournamentParticipantModel.fromJson({
      'payment_status': 'unpaid',
      'registration_status': 'pending_payment',
    });
    expect(p.canRecordCash, isTrue);
    for (final state in [
      'waitlist',
      'eliminated',
      'expired',
      'cancelled',
      'withdrawn',
      'no_show',
      'unknown',
    ]) {
      expect(
        TournamentParticipantModel.fromJson({
          'payment_status': 'unpaid',
          'registration_status': state,
        }).canRecordCash,
        isFalse,
      );
    }
  });
  test(
    'pending proof and unknown payment states never offer cash collection',
    () {
      for (final status in [
        'pending',
        'refund_pending',
        'cancelled',
        'future_state',
      ]) {
        final p = TournamentParticipantModel.fromJson({
          'payment_status': status,
          'registration_status': 'pending_payment',
        });
        expect(p.canRecordCash, isFalse);
      }
    },
  );
  test('a rejected submission keeps the backend rejection reason', () {
    final p = TournamentParticipantModel.fromJson({
      'payment_status': 'unpaid',
      'payment_rejection_reason': 'Unreadable receipt',
      'registration_status': 'pending_payment',
    });
    expect(p.rejectionReason, 'Unreadable receipt');
    expect(p.paymentStatus, ParticipantPaymentStatus.rejected);
  });
}
