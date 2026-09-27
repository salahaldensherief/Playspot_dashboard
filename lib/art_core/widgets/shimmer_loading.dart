import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class ShimmerLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final ShapeBorder shapeBorder;

  const ShimmerLoading.rectangular({
    super.key,
    this.width,
    this.height,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerLoading.circular({
    super.key,
    this.width,
    this.height,
    this.shapeBorder = const CircleBorder(),
  });

  ShimmerLoading.rounded({
    super.key,
    this.width,
    this.height,
    double borderRadius = 12,
  }) : shapeBorder = RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBackground,
      highlightColor: AppColors.mutedBackground.withValues(alpha: 0.5),
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.grey[400]!,
          shape: shapeBorder,
        ),
      ),
    );
  }
}

class TableShimmer extends StatelessWidget {
  final int rows;
  final int columns;

  const TableShimmer({
    super.key,
    this.rows = 5,
    this.columns = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(
              columns,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
                  child: ShimmerLoading.rectangular(height: 20.h),
                ),
              ),
            ),
          ),
          const Divider(),
          ...List.generate(
            rows,
            (index) => Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                children: List.generate(
                  columns,
                  (index) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: ShimmerLoading.rectangular(height: 15.h),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridShimmer extends StatelessWidget {
  final int itemCount;
  final double aspectRatio;

  const GridShimmer({
    super.key,
    this.itemCount = 6,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      addSemanticIndexes: false,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 16.r,
        mainAxisSpacing: 16.r,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) =>  ShimmerLoading.rounded(
        height: double.infinity,
        width: double.infinity,
      ),
    );
  }
}

class CardShimmer extends StatelessWidget {
  const CardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading.rounded(width: 150.w, height: 24.h),
          SizedBox(height: 16.h),
          ShimmerLoading.rounded(width: double.infinity, height: 100.h),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: ShimmerLoading.rounded(height: 40.h)),
              SizedBox(width: 16.w),
              Expanded(child: ShimmerLoading.rounded(height: 40.h)),
            ],
          ),
        ],
      ),
    );
  }
}
