import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/theme/operations_tokens.dart';
import '../../../../art_core/widgets/operations_section.dart';
import '../../../requests/domain/entities/client_request_entity.dart';
import 'session_operations_summary.dart';
import 'session_financial_summary.dart';
import 'cashier_session_header.dart';
import 'session_customer_facts.dart';
import 'session_activity_facts.dart';

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
    EasyLocalization.of(context);
    return Container(
      decoration: OperationsTokens.panel,
      padding: const EdgeInsets.all(OperationsTokens.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CashierSessionHeader(
            roomName: summary.booking.roomName,
            onManage: onManage,
          ),
          const Divider(),
          OperationsSection(
            title: 'cashier.sessionSection'.tr(),
            child: SessionCustomerFacts(booking: summary.booking),
          ),
          const Divider(),
          OperationsSection(
            title: 'cashier.paymentSection'.tr(),
            child: SessionFinancialSummary(booking: summary.booking),
          ),
          const Divider(),
          OperationsSection(
            title: 'cashier.activitySection'.tr(),
            child: SessionActivityFacts(summary: summary, requests: requests),
          ),
        ],
      ),
    );
  }
}
