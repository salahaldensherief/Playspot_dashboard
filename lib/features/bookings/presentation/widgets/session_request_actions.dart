import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/theme/operations_tokens.dart';
import '../../../requests/domain/entities/client_request_entity.dart';
import '../../../requests/presentation/client_requests_cubit.dart';
import '../../../requests/presentation/client_requests_state.dart';
import '../../../permissions/presentation/cubit/permissions_cubit.dart';
import '../../../auth/presentation/login/login_cubit.dart';
import '../../../../core/utils/permission_extension.dart';
part 'session_request_actions_state.dart';

class SessionRequestActions extends StatefulWidget {
  final ClientRequestEntity request;
  const SessionRequestActions({super.key, required this.request});
  @override
  State<SessionRequestActions> createState() => _SessionRequestActionsState();
}
