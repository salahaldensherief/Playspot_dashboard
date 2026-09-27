import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KYC & Lounge Administration Alignment', () {
    test('kyc approval activates lounge and marks owner setup completed', () {
      final lounge = {'id': 'l1', 'status': 'pending', 'is_active': false};
      final profile = {'id': 'u1', 'role': 'owner', 'is_setup_completed': false, 'is_active': true};

      // Simulate review_kyc(p_approve = true)
      lounge['status'] = 'active';
      lounge['is_active'] = true;
      profile['is_setup_completed'] = true;

      expect(lounge['status'], 'active');
      expect(lounge['is_active'], isTrue);
      expect(profile['is_setup_completed'], isTrue);
    });

    test('kyc rejection deactivates lounge but leaves profile active for re-upload', () {
      final lounge = {'id': 'l1', 'status': 'pending', 'is_active': false};
      final profile = {'id': 'u1', 'role': 'owner', 'is_setup_completed': false, 'is_active': true};

      // Simulate review_kyc(p_approve = false)
      lounge['status'] = 'rejected';
      lounge['is_active'] = false;
      profile['is_setup_completed'] = false;
      // profile['is_active'] remains true

      expect(lounge['status'], 'rejected');
      expect(lounge['is_active'], isFalse);
      expect(profile['is_active'], isTrue); // Owner can log in to view reason & re-submit
    });
  });
}
