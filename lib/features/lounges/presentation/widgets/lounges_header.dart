import 'package:easy_localization/easy_localization.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_adaptive_page_header.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/owner_provisioning_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import '../cubit/lounge_cubit.dart';
import '../cubit/lounge_state.dart';
import 'add_lounge_dialog.dart';

class LoungesHeader extends StatelessWidget {
  const LoungesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // Static AppStrings getters need an inherited locale dependency so a
    // language change refreshes the labels even without a Cubit emission.
    context.locale;
    return AppAdaptivePageHeader(
      title: AppStrings.lounges,
      subtitle: AppStrings.loungesHeaderSubtitle,
      primaryAction: AppButton(
        text: AppStrings.createLoungeAndOwner,
        icon: Icons.add,
        onPressed: () => _showAddLoungeDialog(context),
      ),
    );
  }

  void _showAddLoungeDialog(BuildContext context) {
    final cubit = context.read<LoungeCubit>();
    showDialog(
      context: context,
      builder: (diagContext) => BlocConsumer<LoungeCubit, LoungeState>(
        bloc: cubit,
        listener: (context, state) {
          if (state.status == LoungeStatus.success &&
              state.errorMessage == null) {
            // We only want to show success if it was an "add" action,
            // but for simplicity we can just check if state is success.
            // However, fetchLounges also sets success.
          }
          if (state.status == LoungeStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ownerProvisioningMessage(state.errorMessage)),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        builder: (context, state) {
          return AddLoungeDialog(
            isLoading: state.status == LoungeStatus.loading,
            onSave:
                ({
                  required String loungeName,
                  String? address,
                  String? phone,
                  required String ownerName,
                  required String ownerEmail,
                  String? ownerPhone,
                  String? ownerPassword,
                }) async {
                  return cubit.createLoungeWithOwner(
                    loungeName: loungeName,
                    address: address,
                    phone: phone,
                    ownerName: ownerName,
                    ownerEmail: ownerEmail,
                    ownerPhone: ownerPhone,
                    ownerPassword: ownerPassword,
                  );
                },
          );
        },
      ),
    );
  }
}
