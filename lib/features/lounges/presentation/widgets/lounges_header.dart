import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.lounges,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.loungesHeaderSubtitle,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        AppButton(
          text: AppStrings.addNewLounge,
          icon: Icons.add,
          onPressed: () => _showAddLoungeDialog(context),
        ),
      ],
    );
  }

  void _showAddLoungeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (diagContext) => BlocBuilder<LoungeCubit, LoungeState>(
        bloc: context.read<LoungeCubit>(),
        builder: (context, state) {
          return AddLoungeDialog(
            isLoading: state.status == LoungeStatus.loading,
            onSave: (lounge, ownerName, ownerEmail, ownerPassword) {
              context.read<LoungeCubit>().createLoungeAndAdmin(
                lounge: lounge,
                ownerName: ownerName,
                ownerEmail: ownerEmail,
                ownerPassword: ownerPassword,
              );
            },
          );
        },
      ),
    );
  }
}
