import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/features/integrations/domain/services/bridge_setup_planner.dart';

/// Advisory questionnaire in the existing onboarding sequence.
///
/// Answers are saved only in the existing browser-local onboarding draft.
/// They are NOT transmitted, and NO integration is activated by this widget.
class BridgeReadinessStep extends StatelessWidget {
  final Map<String, dynamic> answers;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const BridgeReadinessStep({
    super.key,
    required this.answers,
    required this.onChanged,
  });

  static const _systemOptions = <String>[
    'none',
    'cloud',
    'windowsLocal',
    'otherLocal',
    'unknown',
  ];
  static const _yesNoUnknown = <String>['yes', 'no', 'unknown'];
  static const _reachabilityOptions = <String>[
    'publicHttps',
    'localNetwork',
    'unknown',
  ];

  bool get _hasSystem =>
      answers['system'] != null && answers['system'] != 'none';
  bool get _local =>
      answers['system'] == 'windowsLocal' || answers['system'] == 'otherLocal';
  bool get _usesApi => answers['supportsApi'] == 'yes';
  bool get _wantsBooking => answers['wantsOnlineBooking'] != 'no';
  bool get _wantsControl => answers['wantsSessionControl'] == 'yes';

  bool? _yn(String name) => switch (answers[name]) {
    'yes' => true,
    'no' => false,
    _ => null,
  };

  void _change(String name, String? value) {
    final next = Map<String, dynamic>.of(answers);
    if (name == 'system') {
      next.clear(); // Never reuse stale answers after a different system.
    }
    if (name == 'supportsApi' && value != 'yes') {
      next.remove('hasApiDocumentation');
      next.remove('apiReachability');
      next.remove('apiSessionCommandsAvailable');
    }
    if (name == 'wantsSessionControl' && value != 'yes') {
      next.remove('sessionCommandsAvailable');
      next.remove('apiSessionCommandsAvailable');
    }
    if (value == null || value.isEmpty) {
      next.remove(name);
    } else {
      next[name] = value;
    }
    onChanged(next);
  }

  Widget _choice(String field, List<String> options) {
    final current = answers[field]?.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        key: ValueKey('bridge_$field'),
        value: options.contains(current) ? current : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'bridge_step.questions.$field'.tr(),
          border: const OutlineInputBorder(),
        ),
        items: options
            .map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(
                  'bridge_step.options.$value'.tr(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) => _change(field, value),
      ),
    );
  }

  Widget _text(String field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey('bridge_$field'),
        initialValue: answers[field]?.toString() ?? '',
        maxLength: 120,
        decoration: InputDecoration(
          labelText: 'bridge_step.questions.$field'.tr(),
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) => _change(field, value.trim()),
      ),
    );
  }

  BridgeSetupPlan _plan() {
    final system = switch (answers['system']) {
      'none' => ExistingSystemType.none,
      'cloud' => ExistingSystemType.cloud,
      'windowsLocal' => ExistingSystemType.windowsLocal,
      'otherLocal' => ExistingSystemType.otherLocal,
      _ => ExistingSystemType.unknown,
    };
    final reachability = switch (answers['apiReachability']) {
      'publicHttps' => ApiReachability.publicHttps,
      'localNetwork' => ApiReachability.localNetwork,
      _ => ApiReachability.unknown,
    };
    return const BridgeSetupPlanner().evaluate(
      BridgeSetupAnswers(
        system: system,
        vendorName: answers['vendorName']?.toString() ?? '',
        vendorVersion: answers['vendorVersion']?.toString() ?? '',
        integrationPermission: _yn('integrationPermission'),
        supportsApi: _yn('supportsApi'),
        hasApiDocumentation: _yn('hasApiDocumentation'),
        apiReachability: reachability,
        supportsLocalInterface: _yn('supportsLocalInterface'),
        hasWindowsComputer: _yn('hasWindowsComputer'),
        outboundInternetAvailable: _yn('outboundInternetAvailable'),
        availabilityReadable: _yn('availabilityReadable'),
        atomicFutureReservation: _yn('atomicFutureReservation'),
        sessionCommandsAvailable: _yn('sessionCommandsAvailable'),
        apiSessionCommandsAvailable: _yn('apiSessionCommandsAvailable'),
        changeEventsAvailable: _yn('changeEventsAvailable'),
        wantsOnlineBooking: _wantsBooking,
        wantsSessionControl: _wantsControl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'bridge_step.title'.tr(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('bridge_step.introduction'.tr()),
        const SizedBox(height: 16),
        _choice('system', _systemOptions),
        if (answers['system'] != null) ...[
          if (_hasSystem) ...[
            _text('vendorName'),
            _text('vendorVersion'),
            _choice('integrationPermission', _yesNoUnknown),
            _choice('supportsApi', _yesNoUnknown),
            if (_usesApi) ...[
              _choice('hasApiDocumentation', _yesNoUnknown),
              _choice('apiReachability', _reachabilityOptions),
            ],
            if (_local) ...[
              _choice('supportsLocalInterface', _yesNoUnknown),
              _choice('hasWindowsComputer', _yesNoUnknown),
              if (answers['hasWindowsComputer'] == 'yes')
                _choice('outboundInternetAvailable', _yesNoUnknown),
            ],
          ],
          _choice('wantsOnlineBooking', ['yes', 'no']),
          _choice('wantsSessionControl', _yesNoUnknown),
          if (_hasSystem) ...[
            _choice('availabilityReadable', _yesNoUnknown),
            if (_wantsBooking)
              _choice('atomicFutureReservation', _yesNoUnknown),
            if (_wantsControl) ...[
              if (_local) _choice('sessionCommandsAvailable', _yesNoUnknown),
              if (_usesApi)
                _choice('apiSessionCommandsAvailable', _yesNoUnknown),
            ],
            _choice('changeEventsAvailable', _yesNoUnknown),
          ],
        ],
        const SizedBox(height: 8),
        if (answers['system'] != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'bridge_step.result_title'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('bridge_step.routes.${plan.route.name}'.tr()),
                  const SizedBox(height: 8),
                  Text('bridge_step.readiness.${plan.readiness.name}'.tr()),
                  const SizedBox(height: 12),
                  for (final code in plan.actionCodes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• ${'bridge_step.actions.$code'.tr()}'),
                    ),
                  if (plan.blockerCodes.isNotEmpty) ...[
                    const Divider(),
                    Text(
                      'bridge_step.blockers_title'.tr(),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    for (final code in plan.blockerCodes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• ${'bridge_step.blockers.$code'.tr()}'),
                      ),
                  ],
                  const SizedBox(height: 8),
                  Text('bridge_step.not_activated'.tr()),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'bridge_step.no_secrets'.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'bridge_step.local_draft_notice'.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
