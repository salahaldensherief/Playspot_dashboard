import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../cubit/extras_cubit.dart';
import '../cubit/extras_state.dart';
import 'extra_card.dart';

class ExtrasGrid extends StatelessWidget {
  const ExtrasGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExtrasCubit, ExtrasState>(
      builder: (context, state) {
        if (state.status == ExtrasStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
        }
        if (state.status == ExtrasStatus.failure) {
          return Center(child: AppText.body(state.errorMessage ?? 'Error', color: AppColors.danger));
        }
        if (state.status == ExtrasStatus.success) {
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
            itemBuilder: (context, index) => ExtraCard(extra: state.extras[index]),
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
