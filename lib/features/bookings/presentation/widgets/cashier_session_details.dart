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
import 'session_workflow_progress.dart';

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
    final customer = OperationsSection(
      title: 'cashier.sessionSection'.tr(),
      child: SessionCustomerFacts(booking: booking),
    );
    final bill = Container(
      decoration: OperationsTokens.panel.copyWith(
        color: OperationsTokens.surfaceRaised,
      ),
      padding: const EdgeInsets.all(OperationsTokens.padding),
      child: OperationsSection(
        title: 'cashier.paymentSection'.tr(),
        child: SessionFinancialSummary(booking: booking),
      ),
    );
    final activity = OperationsSection(
      title: 'cashier.activitySection'.tr(),
      child: SessionActivityFacts(summary: summary, requests: requests),
    );
    return Container(
      decoration: OperationsTokens.panel,
      padding: const EdgeInsets.all(OperationsTokens.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CashierSessionHeader(roomName: booking.roomName, onManage: onManage),
          const SizedBox(height: 16),
          if (booking.status == BookingStatus.upcoming ||
              booking.status == BookingStatus.inProgress ||
              booking.status == BookingStatus.completed) ...[
            SessionWorkflowProgress(booking: booking),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 760) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [customer, const Divider(), activity],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: bill),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  customer,
                  const SizedBox(height: 8),
                  bill,
                  const SizedBox(height: 8),
                  activity,
                ],
              );
            },
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
