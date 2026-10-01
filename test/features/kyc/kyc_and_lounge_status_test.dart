import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/auth/data/models/user_model.dart';
import 'package:play_spot_dashboard/features/lounges/data/models/lounge_model.dart';

void main() {
  test(
    'persisted pending lounge does not become active when owner setup is complete',
    () {
      final profile = UserModel.fromJson({
        'id': 'owner-1',
        'role': 'owner',
        'is_active': true,
        'is_setup_completed': true,
      });
      final lounge = LoungeModel.fromJson({
        'id': 'lounge-1',
        'name': 'Venue',
        'status': 'pending',
        'is_active': false,
        'is_open': false,
      });
      expect(profile.isActive, isTrue);
      expect(profile.isSetupCompleted, isTrue);
      expect(lounge.status, 'pending');
      expect(lounge.isActive, isFalse);
      expect(lounge.isOpen, isFalse);
    },
  );
  test(
    'persisted rejection keeps the account active and requires setup correction',
    () {
      final profile = UserModel.fromJson({
        'id': 'owner-1',
        'role': 'owner',
        'is_active': true,
        'is_setup_completed': false,
      });
      final lounge = LoungeModel.fromJson({
        'id': 'lounge-1',
        'name': 'Venue',
        'status': 'rejected',
        'is_active': false,
        'is_open': false,
      });
      expect(profile.isActive, isTrue);
      expect(profile.isSetupCompleted, isFalse);
      expect(lounge.status, 'rejected');
      expect(lounge.isActive, isFalse);
      expect(lounge.isOpen, isFalse);
    },
  );
}
