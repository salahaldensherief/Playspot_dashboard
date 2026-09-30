import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/operations_tokens.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../requests/domain/entities/client_request_entity.dart';
import 'session_operations_summary.dart';
import 'session_financial_summary.dart';
import 'session_fact.dart';
import 'session_live_clock.dart';

class CashierSessionDetails extends StatelessWidget {
  final SessionOperationsSummary summary;
  final List<ClientRequestEntity> requests;
  final VoidCallback? onManage;
  const CashierSessionDetails({
    super.key,
    required this.summary,
    required this.requests,
    this.onManage,
  });
  @override
  Widget build(BuildContext context) {
    final booking = summary.booking;
    final locale = context.locale.languageCode;
    return Container(
      decoration: OperationsTokens.panel,
      padding: const EdgeInsets.all(OperationsTokens.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(booking.roomName, style: OperationsTokens.title),
          const SizedBox(height: OperationsTokens.gap),
          SessionFact(
            label: 'cashier.customer'.tr(),
            value: booking.userName?.trim().isNotEmpty == true
                ? booking.userName ?? ''
                : AppStrings.anonymous,
          ),
          if (booking.userPhone?.isNotEmpty == true)
            SessionFact(
              label: AppStrings.phone,
              value: booking.userPhone ?? '',
            ),
          SessionFact(
            label: 'cashier.resource'.tr(),
            value:
                '${booking.roomName} · ${booking.playMode?.tr() ?? 'cashier.unspecified'.tr()}',
          ),
          SessionFact(label: 'cashier.start'.tr(), value: booking.startTime),
          SessionLiveClock(booking: booking),
          const Divider(),
          SessionFinancialSummary(booking: booking),
          const Divider(),
          SessionFact(
            label: 'cashier.next'.tr(),
            value: summary.nextBooking == null
                ? 'cashier.noneLoaded'.tr()
                : '${summary.nextBooking?.userName ?? AppStrings.anonymous} · ${summary.nextBooking?.startTime}',
          ),
          if (summary.hasConflict)
            Text('cashier.conflict'.tr(), style: OperationsTokens.value),
          SessionFact(
            label: 'cashier.requests'.tr(),
            value: requests.isEmpty
                ? 'cashier.noneLoaded'.tr()
                : '${requests.length}',
          ),
          for (final request in requests)
            SessionFact(
              label: locale == 'ar' ? request.titleAr : request.titleEn,
              value: locale == 'ar' ? request.bodyAr : request.bodyEn,
            ),
          SessionFact(
            label: 'cashier.canteen'.tr(),
            value: '${booking.canteenOrders.length}',
          ),
          if (onManage != null)
            AppButton(
              text: 'cashier.actions'.tr(),
              height: 48,
              onPressed: onManage,
            ),
        ],
      ),
    );
  }
}
