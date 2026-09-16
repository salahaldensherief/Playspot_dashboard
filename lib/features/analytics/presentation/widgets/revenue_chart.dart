import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import '../dashboard_cubit.dart';
import '../dashboard_state.dart';

class RevenueChart extends StatelessWidget {
  const RevenueChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.revenueChart != curr.revenueChart,
      builder: (context, state) {
        if (state.status == FeatureStatus.loading && state.revenueChart.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: ShimmerLoading.rounded(
              width: double.infinity,
              height: 250.h,
            ),
          );
        }

        if (state.revenueChart.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart_rounded, size: 40.r, color: AppColors.textMuted),
                SizedBox(height: 8.h),
                AppText.body(
                  AppStrings.noResultsMatching.replaceFirst("\"{}\"", ""),
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
                SizedBox(height: 12.h),
                AppButton(
                  text: AppStrings.refresh,
                  variant: AppButtonVariant.outlined,
                  height: 32.h,
                  onPressed: () {
                    context.read<DashboardCubit>().loadDashboardData();
                  },
                ),
              ],
            ),
          );
        }

        final spots = <FlSpot>[];
        double maxY = 1000;

        for (int i = 0; i < state.revenueChart.length; i++) {
          final val = (state.revenueChart[i]['revenue'] as num?)?.toDouble() ?? 0.0;
          spots.add(FlSpot(i.toDouble(), val));
          if (val > maxY) maxY = val;
        }

        return RepaintBoundary(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.borderDefault.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < state.revenueChart.length && index % 5 == 0) {
                        final day = state.revenueChart[index]['day']?.toString() ?? '';
                        return Padding(
                          padding: EdgeInsets.only(top: 10.h),
                          child: Text(
                            day.length > 5 ? day.substring(5) : day,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 30.h,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 9.sp),
                      );
                    },
                    reservedSize: 40.w,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: state.revenueChart.length.toDouble() - 1,
              minY: 0,
              maxY: maxY * 1.2,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  gradient: const LinearGradient(colors: [AppColors.neonBlue, AppColors.neonCyan]),
                  barWidth: 3.w,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.neonBlue.withValues(alpha: 0.2),
                        AppColors.neonBlue.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
