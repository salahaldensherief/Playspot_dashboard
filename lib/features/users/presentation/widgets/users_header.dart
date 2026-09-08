import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_state.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/widgets/add_lounge_dialog.dart';

class UsersHeader extends StatelessWidget {
  const UsersHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.loungeAdministrators,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.manageAdminsDesc,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
            ),
          ],
        ),
        AppButton(
          text: "Create Lounge & Owner",
          icon: Icons.add,
          onPressed: () => _showAddLoungeAndOwnerDialog(context),
        ),
      ],
    );
  }

  void _showAddLoungeAndOwnerDialog(BuildContext context) {
    final cubit = context.read<LoungeCubit>();
    showDialog(
      context: context,
      builder: (diagContext) => BlocConsumer<LoungeCubit, LoungeState>(
        bloc: cubit,
        listener: (context, state) {
          if (state.status == LoungeStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Error'), backgroundColor: AppColors.danger),
            );
          }
        },
        builder: (context, state) {
          return AddLoungeDialog(
            isLoading: state.status == LoungeStatus.loading,
            onSave: ({
              required String loungeName,
              String? address,
              String? phone,
              required String ownerName,
              required String ownerEmail,
              String? ownerPhone,
              String? ownerPassword,
            }) async {
              await cubit.createLoungeWithOwner(
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
