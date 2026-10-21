import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/integrations/domain/services/bridge_setup_planner.dart';

void main() {
  const planner = BridgeSetupPlanner();

  const cloud = BridgeSetupAnswers(
    system: ExistingSystemType.cloud,
    vendorName: 'Fixture Vendor',
    vendorVersion: '2',
    integrationPermission: true,
    supportsApi: true,
    hasApiDocumentation: true,
    apiReachability: ApiReachability.publicHttps,
    availabilityReadable: true,
    atomicFutureReservation: true,
    changeEventsAvailable: true,
  );

  test(
    'no existing software receives native OS guidance, not a bridge promise',
    () {
      final plan = planner.evaluate(
        const BridgeSetupAnswers(system: ExistingSystemType.none),
      );
      expect(plan.route, BridgeRoute.playspotOs);
      expect(plan.instantBookingAllowed, isFalse);
      expect(plan.sessionControlAllowed, isFalse);
    },
  );

  test('documented cloud API can be considered for a technical pilot', () {
    final plan = planner.evaluate(cloud);
    expect(plan.route, BridgeRoute.cloudApi);
    expect(plan.readiness, BridgeReadiness.technicalPilotCandidate);
    expect(plan.blockerCodes, isEmpty);
    expect(plan.syncStrategy, 'verify_vendor_webhook');
    expect(plan.instantBookingAllowed, isFalse); // No auto-activation
  });

  test('having availability does not imply atomic booking', () {
    final plan = planner.evaluate(
      const BridgeSetupAnswers(
        system: ExistingSystemType.cloud,
        vendorName: 'Fixture Vendor',
        vendorVersion: '2',
        integrationPermission: true,
        supportsApi: true,
        hasApiDocumentation: true,
        apiReachability: ApiReachability.publicHttps,
        availabilityReadable: true,
        atomicFutureReservation: false,
      ),
    );
    expect(
      plan.blockerCodes,
      contains('no_atomic_reservation_manual_confirmation_only'),
    );
    expect(plan.readiness, BridgeReadiness.evidenceRequired);
  });

  test('local Windows agent requires an approved supported interface', () {
    final plan = planner.evaluate(
      const BridgeSetupAnswers(
        system: ExistingSystemType.windowsLocal,
        vendorName: 'Fixture Vendor',
        vendorVersion: '1',
        integrationPermission: true,
        supportsLocalInterface: true,
        hasWindowsComputer: true,
        outboundInternetAvailable: true,
        availabilityReadable: true,
        atomicFutureReservation: true,
      ),
    );
    expect(plan.route, BridgeRoute.localAgent);
    expect(plan.readiness, BridgeReadiness.technicalPilotCandidate);
    expect(plan.actionCodes, contains('pair_agent_with_one_time_code'));
    expect(plan.instantBookingAllowed, isFalse);
  });

  test('missing outbound internet blocks local pilot', () {
    final plan = planner.evaluate(
      const BridgeSetupAnswers(
        system: ExistingSystemType.windowsLocal,
        vendorName: 'Fixture Vendor',
        vendorVersion: '1',
        integrationPermission: true,
        supportsLocalInterface: true,
        hasWindowsComputer: true,
        outboundInternetAvailable: false,
        availabilityReadable: true,
        atomicFutureReservation: true,
      ),
    );
    expect(plan.blockerCodes, contains('verify_windows_and_outbound_https'));
  });

  test('a local app with no interface must not promise bridge support', () {
    final plan = planner.evaluate(
      const BridgeSetupAnswers(
        system: ExistingSystemType.windowsLocal,
        vendorName: 'Fixture Vendor',
        vendorVersion: '1',
        integrationPermission: true,
        supportsApi: false,
        supportsLocalInterface: false,
      ),
    );
    expect(plan.route, BridgeRoute.assessment);
    expect(plan.blockerCodes, contains('no_verified_supported_interface'));
  });

  test('a hybrid path may use API plus approved local session commands', () {
    final plan = planner.evaluate(
      const BridgeSetupAnswers(
        system: ExistingSystemType.windowsLocal,
        vendorName: 'Fixture Vendor',
        vendorVersion: '2',
        integrationPermission: true,
        supportsApi: true,
        hasApiDocumentation: true,
        apiReachability: ApiReachability.publicHttps,
        supportsLocalInterface: true,
        hasWindowsComputer: true,
        outboundInternetAvailable: true,
        apiSessionCommandsAvailable: false,
        sessionCommandsAvailable: true,
        wantsSessionControl: true,
        availabilityReadable: true,
        atomicFutureReservation: true,
      ),
    );
    expect(plan.route, BridgeRoute.hybrid);
    expect(plan.readiness, BridgeReadiness.technicalPilotCandidate);
    expect(plan.sessionControlAllowed, isFalse);
  });

  test('owner permission is never inferred from API access', () {
    final plan = planner.evaluate(
      const BridgeSetupAnswers(
        system: ExistingSystemType.cloud,
        vendorName: 'Fixture Vendor',
        vendorVersion: '2',
        supportsApi: true,
        hasApiDocumentation: true,
        apiReachability: ApiReachability.publicHttps,
        availabilityReadable: true,
        atomicFutureReservation: true,
      ),
    );
    expect(plan.blockerCodes, contains('obtain_integration_permission'));
    expect(plan.readiness, BridgeReadiness.evidenceRequired);
  });

  test('requested session control is blocked without verified support', () {
    final plan = planner.evaluate(
      const BridgeSetupAnswers(
        system: ExistingSystemType.cloud,
        vendorName: 'Fixture Vendor',
        vendorVersion: '2',
        integrationPermission: true,
        supportsApi: true,
        hasApiDocumentation: true,
        apiReachability: ApiReachability.publicHttps,
        availabilityReadable: true,
        atomicFutureReservation: true,
        wantsSessionControl: true,
        sessionCommandsAvailable: false,
      ),
    );
    expect(plan.blockerCodes, contains('session_commands_not_verified'));
    expect(plan.sessionControlAllowed, isFalse);
  });
}
