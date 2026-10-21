/// Pure, advisory readiness classifier for the proposed external-system wizard.
///
/// This is NOT an integration connector and MUST NOT enable bookings, issue
/// session commands, or persist credentials. Server-side authorization,
/// vendor certification and a supervised pilot are required separately.
enum ExistingSystemType { none, cloud, windowsLocal, otherLocal, unknown }

enum ApiReachability { publicHttps, localNetwork, unknown }

enum BridgeRoute { playspotOs, cloudApi, localAgent, hybrid, assessment }

enum BridgeReadiness { setupGuidance, evidenceRequired, technicalPilotCandidate }

class BridgeSetupAnswers {
  final ExistingSystemType system;
  final String vendorName;
  final String vendorVersion;
  final bool? integrationPermission;
  final bool? supportsApi;
  final bool? hasApiDocumentation;
  final ApiReachability apiReachability;
  final bool? supportsLocalInterface;
  final bool? hasWindowsComputer;
  final bool? outboundInternetAvailable;
  final bool? availabilityReadable;
  final bool? atomicFutureReservation;
  final bool? sessionCommandsAvailable;
  final bool? apiSessionCommandsAvailable;
  final bool? changeEventsAvailable;
  final bool wantsOnlineBooking;
  final bool wantsSessionControl;

  const BridgeSetupAnswers({
    required this.system,
    this.vendorName = '',
    this.vendorVersion = '',
    this.integrationPermission,
    this.supportsApi,
    this.hasApiDocumentation,
    this.apiReachability = ApiReachability.unknown,
    this.supportsLocalInterface,
    this.hasWindowsComputer,
    this.outboundInternetAvailable,
    this.availabilityReadable,
    this.atomicFutureReservation,
    this.sessionCommandsAvailable,
    this.apiSessionCommandsAvailable,
    this.changeEventsAvailable,
    this.wantsOnlineBooking = true,
    this.wantsSessionControl = false,
  });
}

class BridgeSetupPlan {
  final BridgeRoute route;
  final BridgeReadiness readiness;
  final List<String> actionCodes;
  final List<String> blockerCodes;
  final bool instantBookingAllowed;
  final bool sessionControlAllowed;
  final String syncStrategy;

  BridgeSetupPlan({
    required this.route,
    required this.readiness,
    required List<String> actionCodes,
    required List<String> blockerCodes,
    required this.instantBookingAllowed,
    required this.sessionControlAllowed,
    required this.syncStrategy,
  }) : actionCodes = List.unmodifiable(actionCodes),
       blockerCodes = List.unmodifiable(blockerCodes);

  bool get needsHumanReview => blockerCodes.isNotEmpty;
}

/// All status values are advice only; do not interpret as activated features.
class BridgeSetupPlanner {
  const BridgeSetupPlanner();

  BridgeSetupPlan evaluate(BridgeSetupAnswers a) {
    if (a.system == ExistingSystemType.none) {
      return BridgeSetupPlan(
        route: BridgeRoute.playspotOs,
        readiness: BridgeReadiness.setupGuidance,
        actionCodes: ['configure_playspot_os', 'map_rooms', 'staff_training'],
        blockerCodes: const [],
        instantBookingAllowed: false,
        sessionControlAllowed: false,
        syncStrategy: 'native',
      );
    }

    final actions = <String>['identify_vendor_version', 'list_rooms'];
    final blockers = <String>[];
    if (a.vendorName.trim().isEmpty || a.vendorVersion.trim().isEmpty) {
      blockers.add('identify_vendor_version');
    }
    if (a.integrationPermission != true) {
      blockers.add('obtain_integration_permission');
    }

    final apiDocumented =
        a.supportsApi == true && a.hasApiDocumentation == true;
    final localSupported = a.supportsLocalInterface == true;
    final localHostReady = a.hasWindowsComputer == true &&
        a.outboundInternetAvailable == true;
    final apiNeedsAgent =
        a.supportsApi == true &&
        a.apiReachability == ApiReachability.localNetwork;
    final canReachCloudApi =
        apiDocumented && a.apiReachability == ApiReachability.publicHttps;
    final canUseLocalAgent = (localSupported || apiNeedsAgent) &&
        a.system == ExistingSystemType.windowsLocal;

    BridgeRoute route;
    if (canReachCloudApi && canUseLocalAgent && a.wantsSessionControl &&
        a.apiSessionCommandsAvailable != true &&
        a.sessionCommandsAvailable == true) {
      route = BridgeRoute.hybrid;
    } else if (canReachCloudApi) {
      route = BridgeRoute.cloudApi;
    } else if (canUseLocalAgent) {
      route = BridgeRoute.localAgent;
    } else {
      route = BridgeRoute.assessment;
    }

    if (route == BridgeRoute.cloudApi || route == BridgeRoute.hybrid) {
      actions.add('request_api_sandbox_without_credentials_in_form');
      actions.add('validate_api_scopes_rate_limits_and_auth');
    }
    if (route == BridgeRoute.localAgent || route == BridgeRoute.hybrid) {
      actions.add('install_signed_local_agent_after_approval');
      actions.add('pair_agent_with_one_time_code');
      if (!localHostReady) blockers.add('verify_windows_and_outbound_https');
    }
    if (route == BridgeRoute.assessment) {
      actions.add('contact_vendor_support');
      blockers.add('no_verified_supported_interface');
    }
    if (a.supportsApi == true && !apiDocumented) {
      blockers.add('collect_official_api_documentation');
    }
    if (a.supportsApi == true &&
        a.apiReachability == ApiReachability.unknown &&
        route == BridgeRoute.assessment) {
      blockers.add('confirm_api_reachability');
    }

    // Availability and reservation authority are independent capabilities.
    // An "available" response alone is NOT an atomic capacity reservation.
    if (a.wantsOnlineBooking) {
      actions.add('map_external_rooms_to_playspot_ids');
      actions.add('test_booking_collision_with_vendor');
      if (a.availabilityReadable != true) {
        blockers.add('verify_availability_read');
      }
      if (a.atomicFutureReservation != true) {
        blockers.add('no_atomic_reservation_manual_confirmation_only');
      }
    }
    if (a.wantsSessionControl) {
      actions.add('test_start_extend_end_without_real_customer');
      final hasCommandChannel = switch (route) {
        BridgeRoute.cloudApi => a.apiSessionCommandsAvailable == true,
        BridgeRoute.localAgent || BridgeRoute.hybrid =>
          a.sessionCommandsAvailable == true,
        _ => false,
      };
      if (!hasCommandChannel) {
        blockers.add('session_commands_not_verified');
      }
    }
    actions.add('reconcile_both_systems_after_disconnect');
    actions.add('review_by_playspot_integration_team');

    final eligibleForPilot = blockers.isEmpty &&
        route != BridgeRoute.assessment &&
        a.integrationPermission == true;
    // Even when the vendor says these features exist, they are disabled until
    // the server verifies capabilities, authorization, and pilot results.
    return BridgeSetupPlan(
      route: route,
      readiness: eligibleForPilot
          ? BridgeReadiness.technicalPilotCandidate
          : BridgeReadiness.evidenceRequired,
      actionCodes: actions,
      blockerCodes: blockers,
      instantBookingAllowed: false,
      sessionControlAllowed: false,
      syncStrategy: a.changeEventsAvailable == true
          ? 'verify_vendor_webhook'
          : 'assess_polling_or_manual_refresh',
    );
  }
}
