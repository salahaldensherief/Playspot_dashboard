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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900 || textScale > 1.3;

        final title = Column(
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
        );

        final action = AppButton(
          text: AppStrings.createLoungeAndOwner,
          icon: Icons.add,
          onPressed: () => _showAddLoungeDialog(context),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              SizedBox(height: 16.h),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: action,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            SizedBox(width: 20.w),
            Flexible(child: action),
          ],
        );
      },
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
                content: Text(state.errorMessage ?? 'Error'),
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
                  return await cubit.createLoungeWithOwner(
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
