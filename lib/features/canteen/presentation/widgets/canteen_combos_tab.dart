import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_empty_state_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import '../../../lounges/presentation/cubit/extras_cubit.dart';
import '../canteen_cubit.dart';
import '../canteen_state.dart';
import 'combo_card.dart';
import 'combo_editor_modal.dart';

class CanteenCombosTab extends StatelessWidget {
  final String loungeId;

  const CanteenCombosTab({super.key, required this.loungeId});

  void _openAddModal(BuildContext context) {
    final canteenCubit = context.read<CanteenCubit>();
    final extrasCubit = context.read<ExtrasCubit>();

    showDialog(
      context: context,
      builder: (ctx) => ComboEditorModal(
        loungeId: loungeId,
        availableExtras: extrasCubit.state.extras,
        onSave: (combo) => canteenCubit.saveCombo(combo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanteenCubit, CanteenState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.combos != curr.combos ||
          prev.isSaving != curr.isSaving,
      builder: (context, state) {
        if (state.status == CanteenStatus.loading && state.combos.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: ShimmerLoading.rectangular(
              width: double.infinity,
              height: 200.h,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.subHeading(
                  '${AppStrings.combosManager} (${state.combos.length})',
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                AppButton(
                  text: AppStrings.addCombo,
                  icon: Icons.add,
                  onPressed: () => _openAddModal(context),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            if (state.combos.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: AppEmptyStateWidget(
                  title: AppStrings.noCombosFound,
                  subtitle: 'canteen_combos_empty_description'.tr(),
                  icon: Icons.fastfood_outlined,
                  actionText: AppStrings.addCombo,
                  onActionTextPressed: () => _openAddModal(context),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  final crossAxisCount = isWide ? 2 : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisExtent: 220.h,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                    ),
                    itemCount: state.combos.length,
                    itemBuilder: (context, index) {
                      final combo = state.combos[index];
                      final canteenCubit = context.read<CanteenCubit>();
                      final extrasCubit = context.read<ExtrasCubit>();

                      return ComboCard(
                        combo: combo,
                        onToggleActive: (_) =>
                            canteenCubit.toggleComboActive(combo),
                        onDelete: () => canteenCubit.deleteCombo(combo.id),
                        onEdit: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => ComboEditorModal(
                              loungeId: loungeId,
                              initialCombo: combo,
                              availableExtras: extrasCubit.state.extras,
                              onSave: (updated) =>
                                  canteenCubit.saveCombo(updated),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
