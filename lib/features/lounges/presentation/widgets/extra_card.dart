import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/responsive/app_breakpoints.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../../domain/entities/extra_entity.dart';
import 'extra_card_desktop.dart';
import 'extra_card_mobile.dart';

class ExtraCard extends StatelessWidget {
  final ExtraEntity extra;

  const ExtraCard({super.key, required this.extra});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final canEdit = user?.canManageMenuStructure ?? false;
    final loungeId = user?.loungeId ?? extra.loungeId;
    final isMobile = AppBreakpoints.isMobile(context);

    if (isMobile) {
      return ExtraCardMobile(
        extra: extra,
        canEdit: canEdit,
        loungeId: loungeId,
      );
    }
    return ExtraCardDesktop(
      extra: extra,
      canEdit: canEdit,
      loungeId: loungeId,
    );
  }
}
