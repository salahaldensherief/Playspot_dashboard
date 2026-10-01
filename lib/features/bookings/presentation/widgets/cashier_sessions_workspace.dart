import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/responsive/app_breakpoints.dart';
import '../../domain/entities/booking.dart';
import '../../../requests/domain/entities/client_request_entity.dart';
import 'cashier_session_details.dart';
import 'session_clock_host.dart';
import 'session_ticker.dart';
import 'cashier_session_rail.dart';
import 'cashier_sessions_split_view.dart';
import 'cashier_session_sheet.dart';
import 'session_operations_summary.dart';
import '../../domain/entities/live_sessions_operations_groups.dart';

part 'cashier_sessions_workspace_state.dart';

class CashierSessionsWorkspace extends StatefulWidget {
  final List<Booking> bookings;
  final List<ClientRequestEntity> requests;
  final ValueChanged<Booking> onManage;
  const CashierSessionsWorkspace({
    super.key,
    required this.bookings,
    this.requests = const [],
    required this.onManage,
  });
  @override
  State<CashierSessionsWorkspace> createState() =>
      _CashierSessionsWorkspaceState();
}
