import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../auth/presentation/login/login_cubit.dart';
import '../../../auth/presentation/login/login_state.dart';

class KycPendingPage extends StatelessWidget {
  const KycPendingPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.scaffoldBackground,
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BlocBuilder<LoginCubit, LoginState>(
                buildWhen: (previous, current) =>
                    previous.status != current.status ||
                    previous.userLounge != current.userLounge,
                builder: (context, state) => _card(context, state),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _card(BuildContext context, LoginState state) {
    final status = _status(state);
    final busy =
        state.status == LoginStatus.checking ||
        state.status == LoginStatus.loading;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.pending_actions_outlined,
          size: 56,
          color: AppColors.warning,
        ),
        const SizedBox(height: 20),
        AppText.heading(
          'kyc_pending.$status.title'.tr(),
          fontSize: 24,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (state.userLounge?.name.isNotEmpty == true)
          AppText.subHeading(
            state.userLounge!.name,
            fontSize: 18,
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        AppText.body(
          'kyc_pending.$status.description'.tr(),
          fontSize: 16,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        OverflowBar(
          spacing: 12,
          overflowSpacing: 12,
          alignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: busy
                  ? null
                  : () => context.read<LoginCubit>().checkInitialAuth(),
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text('kyc_pending.refresh'.tr()),
            ),
            OutlinedButton(
              onPressed: () => context.read<LoginCubit>().logout(),
              child: Text(AppStrings.logout),
            ),
          ],
        ),
      ],
    );
  }

  String _status(LoginState state) {
    final lounge = state.userLounge;
    if (lounge == null) return 'unavailable';
    if (lounge.status == 'pending') return 'pending';
    if (lounge.status == 'rejected') return 'rejected';
    return 'disabled';
  }
}
