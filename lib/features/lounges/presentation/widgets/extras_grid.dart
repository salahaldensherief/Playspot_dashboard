import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/core/responsive/app_breakpoints.dart';
import '../cubit/extras_cubit.dart';
import '../cubit/extras_state.dart';
import 'extra_card.dart';

class ExtrasGrid extends StatelessWidget {
  const ExtrasGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = AppBreakpoints.isMobileWidth(width);
    final isTablet = AppBreakpoints.isTabletWidth(width);

    final int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    final double childAspectRatio = isMobile ? 2.8 : (isTablet ? 1.1 : 0.85);

    return BlocBuilder<ExtrasCubit, ExtrasState>(
      builder: (context, state) {
        if (state.status == ExtrasStatus.loading) {
          return GridShimmer(
            itemCount: isMobile ? 4 : 8,
            aspectRatio: childAspectRatio,
          );
        }
        if (state.status == ExtrasStatus.failure) {
          return Center(
            child: AppText.body(state.errorMessage ?? AppStrings.error, color: AppColors.danger),
          );
        }
        if (state.status == ExtrasStatus.success) {
          if (state.extras.isEmpty) {
            return _buildEmptyState();
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: isMobile ? 12.w : 20.w,
              mainAxisSpacing: isMobile ? 12.h : 20.h,
              childAspectRatio: childAspectRatio,
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
          SizedBox(height: 60.h),
          Icon(Icons.restaurant_menu, color: AppColors.textSecondary, size: 64.r),
          SizedBox(height: 16.h),
          AppText.body(AppStrings.noItemsAdded, fontSize: 18.sp),
        ],
      ),
    );
  }
}
