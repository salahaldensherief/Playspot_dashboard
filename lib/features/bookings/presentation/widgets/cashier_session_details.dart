import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/theme/operations_tokens.dart';
import '../../../../art_core/widgets/operations_section.dart';
import '../../../requests/domain/entities/client_request_entity.dart';
import '../../domain/entities/booking.dart';
import 'booking_card_actions.dart';
import 'booking_details_dialog.dart';
import 'session_operations_summary.dart';
import 'session_financial_summary.dart';
import 'cashier_session_header.dart';
import 'session_customer_facts.dart';
import 'session_activity_facts.dart';

class CashierSessionDetails extends StatelessWidget {
  final SessionOperationsSummary summary;
  final List<ClientRequestEntity> requests;
  final VoidCallback? onManage;
  final bool showActions;
  const CashierSessionDetails({
    super.key,
    required this.summary,
    required this.requests,
    this.onManage,
    this.showActions = true,
  });
  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final booking = summary.booking;
    return Container(
      decoration: OperationsTokens.panel,
      padding: const EdgeInsets.all(OperationsTokens.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CashierSessionHeader(roomName: booking.roomName, onManage: onManage),
          const Divider(),
          OperationsSection(
            title: 'cashier.sessionSection'.tr(),
            child: SessionCustomerFacts(booking: booking),
          ),
          const Divider(),
          OperationsSection(
            title: 'cashier.paymentSection'.tr(),
            child: SessionFinancialSummary(booking: booking),
          ),
          const Divider(),
          OperationsSection(
            title: 'cashier.activitySection'.tr(),
            child: SessionActivityFacts(summary: summary, requests: requests),
          ),
          if (showActions && booking.status != BookingStatus.inProgress) ...[
            const Divider(),
            BookingCardActions(
              booking: booking,
              isPaid: booking.paymentStatus == PaymentStatus.paid,
              isPending: booking.status == BookingStatus.pending,
              isCanStartSession: booking.status == BookingStatus.upcoming,
              onOpenDetails:
                  onManage ??
                  () => BookingDetailsDialog.show(context, booking: booking),
            ),
          ],
        ],
      ),
    );
  }
}
