import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/operations_tokens.dart';
import '../../../../art_core/widgets/operations_facts_grid.dart';
import '../../../requests/domain/entities/client_request_entity.dart';
import 'session_fact.dart';
import 'session_operations_summary.dart';

class SessionActivityFacts extends StatelessWidget {
  final SessionOperationsSummary summary;
  final List<ClientRequestEntity> requests;
  const SessionActivityFacts({
    super.key,
    required this.summary,
    required this.requests,
  });
  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OperationsFactsGrid(
          children: [
            SessionFact(
              label: 'cashier.next'.tr(),
              value: summary.nextBooking == null
                  ? 'cashier.noneLoaded'.tr()
                  : '${summary.nextBooking?.userName ?? AppStrings.anonymous} · ${summary.nextBooking?.startTime}',
            ),
            SessionFact(
              label: 'cashier.requests'.tr(),
              value: '${requests.length}',
            ),
            SessionFact(
              label: 'cashier.canteen'.tr(),
              value: '${summary.booking.canteenOrders.length}',
            ),
          ],
        ),
        if (summary.hasConflict)
          Text('cashier.conflict'.tr(), style: OperationsTokens.value),
        for (final request in requests)
          SessionFact(
            label: locale == 'ar' ? request.titleAr : request.titleEn,
            value: locale == 'ar' ? request.bodyAr : request.bodyEn,
          ),
      ],
    );
  }
}
