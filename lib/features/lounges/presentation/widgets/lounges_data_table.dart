import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import '../../domain/entities/lounge.dart';
import '../cubit/lounge_cubit.dart';
import '../cubit/lounge_state.dart';
import 'edit_lounge_dialog.dart';

class LoungesDataTable extends StatelessWidget {
  const LoungesDataTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoungeCubit, LoungeState>(
      builder: (context, state) {
        if (state.status == LoungeStatus.loading && state.lounges.isEmpty) {
          return const TableShimmer(columns: 6);
        }

        final lounges = state.lounges;

        if (lounges.isEmpty) {
          return Center(
            child: Column(
              children: [
                SizedBox(height: 100.h),
                Icon(Icons.business_outlined, size: 64.r, color: AppColors.textMuted),
                SizedBox(height: 16.h),
                Text(AppStrings.noLoungesFound, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return DataTableWidget(
          columns: [
            AppStrings.loungeName,
            AppStrings.loungeOwnerAdmin,
            AppStrings.location,
            AppStrings.pricePerHour,
            AppStrings.status,
            AppStrings.actions
          ],
          rows: lounges.map((lounge) => DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(lounge.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    Text('${lounge.availableRooms ?? 0} ${AppStrings.rooms}', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
                  ],
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(lounge.ownerName ?? AppStrings.notAssigned, style: const TextStyle(color: AppColors.textPrimary)),
                    Text(lounge.ownerEmail ?? '-', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
                  ],
                ),
              ),
              DataCell(Text(lounge.city ?? lounge.location ?? 'N/A', style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(Text('\$${lounge.pricePerHour.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textPrimary))),
              DataCell(
                lounge.status == 'pending' 
                  ? StatusBadge.warning(AppStrings.pending) 
                  : lounge.isOpen 
                    ? StatusBadge.success(AppStrings.active) 
                    : StatusBadge.danger(AppStrings.inactive)
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20.r),
                      onPressed: () => _showEditDialog(context, lounge),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
                      onPressed: () => _confirmDelete(context, lounge.id, lounge.name),
                    ),
                  ],
                ),
              ),
            ],
          )).toList(),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Lounge lounge) {
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
          return EditLoungeDialog(
            lounge: lounge,
            isLoading: state.status == LoungeStatus.loading,
            onSave: (updatedLounge) async {
              await cubit.updateLounge(updatedLounge);
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String loungeId, String name) {
    final cubit = context.read<LoungeCubit>();
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.deleteLounge, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${AppStrings.deleteLoungeWarning} ($name)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagContext), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              cubit.deleteLounge(loungeId);
              Navigator.pop(diagContext);
            },
            child: Text(AppStrings.delete, style: const TextStyle(color: AppColors.danger))
          ),
        ],
      ),
    );
  }
}
