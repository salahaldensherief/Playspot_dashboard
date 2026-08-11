import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../cubit/extras_cubit.dart';
import '../widgets/add_extra_dialog.dart';
import '../../domain/entities/extra_entity.dart';

class ExtrasManagementPage extends StatelessWidget {
  const ExtrasManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? '';

    return BlocProvider(
      create: (context) => sl<ExtrasCubit>()..loadExtras(loungeId),
      child: Builder(
        builder: (context) {
          return DashboardLayout(
            title: AppStrings.extras,
            activeRoute: 'Extras',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, loungeId),
                SizedBox(height: 32.h),
                const _ExtrasGrid(),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String loungeId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.heading(AppStrings.menuManagement, fontSize: 24.sp),
            AppText.body(AppStrings.menuManagementSubtitle),
          ],
        ),
        AppButton(
          text: AppStrings.addExtraItem,
          icon: Icons.add,
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => BlocProvider.value(
                value: context.read<ExtrasCubit>(),
                child: ExtraDialog(loungeId: loungeId),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ExtrasGrid extends StatelessWidget {
  const _ExtrasGrid();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExtrasCubit, ExtrasState>(
      builder: (context, state) {
        if (state is ExtrasLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
        }
        if (state is ExtrasError) {
          return Center(child: AppText.body(state.message, color: AppColors.danger));
        }
        if (state is ExtrasLoaded) {
          if (state.extras.isEmpty) {
            return _buildEmptyState();
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 20.w,
              mainAxisSpacing: 20.h,
              childAspectRatio: 0.8,
            ),
            itemCount: state.extras.length,
            itemBuilder: (context, index) => _ExtraCard(extra: state.extras[index]),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 100.h),
          Icon(Icons.restaurant_menu, color: AppColors.textSecondary, size: 64.r),
          SizedBox(height: 16.h),
          AppText.body(AppStrings.noItemsAdded, fontSize: 18.sp),
        ],
      ),
    );
  }
}

class _ExtraCard extends StatelessWidget {
  final ExtraEntity extra;
  const _ExtraCard({required this.extra});

  @override
  Widget build(BuildContext context) {
    final loungeId = context.read<LoginCubit>().state.user?.loungeId ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.divider.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                image: extra.imageUrl != null 
                  ? DecorationImage(image: NetworkImage(extra.imageUrl!), fit: BoxFit.cover)
                  : null,
              ),
              child: extra.imageUrl == null 
                ? const Center(child: Icon(Icons.fastfood, color: AppColors.textSecondary, size: 48))
                : null,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge.info(extra.category),
                    AppText.subHeading(
                      '${extra.price} ${AppStrings.priceEgp}',
                      color: AppColors.neonBlue,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                AppText.heading(extra.name, fontSize: 16.sp, isOrbitron: false),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20.r),
                          onPressed: () => _showEditDialog(context, loungeId),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    Switch(
                      value: !extra.isOutOfStock,
                      activeColor: AppColors.neonBlue,
                      onChanged: (val) {
                        context.read<ExtrasCubit>().toggleStock(extra.id, !val, loungeId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String loungeId) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ExtrasCubit>(),
        child: ExtraDialog(loungeId: loungeId, extra: extra),
      ),
    );
  }
}
