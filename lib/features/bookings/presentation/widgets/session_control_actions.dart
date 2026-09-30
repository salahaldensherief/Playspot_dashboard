import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../../../art_core/theme/operations_tokens.dart';
import '../../domain/entities/booking.dart';
import '../cubit/booking_cubit.dart';
import '../../../analytics/presentation/dashboard_cubit.dart';
import '../../../permissions/presentation/cubit/permissions_cubit.dart';
import '../../../auth/presentation/login/login_cubit.dart';
import '../../../../core/utils/permission_extension.dart';
import 'swap_room_dialog.dart';
part 'session_control_actions_state.dart';

class SessionControlActions extends StatefulWidget {
  final Booking booking;
  const SessionControlActions({super.key, required this.booking});
  @override
  State<SessionControlActions> createState() => _SessionControlActionsState();
}
