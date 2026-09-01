import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import '../dashboard_cubit.dart';
import '../dashboard_state.dart';

class RevenueChart extends StatelessWidget {
  const RevenueChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      buildWhen: (prev, curr) => prev.revenueChart != curr.revenueChart,
      builder: (context, state) {
        if (state.revenueChart.isEmpty) {
          return Center(child: Text(AppStrings.noResultsMatching.replaceFirst("\"{}\"", ""), style: const TextStyle(color: AppColors.textSecondary)));
        }

        final spots = <FlSpot>[];
        double maxY = 1000;
        
        for (int i = 0; i < state.revenueChart.length; i++) {
          final val = (state.revenueChart[i]['revenue'] as num?)?.toDouble() ?? 0.0;
          spots.add(FlSpot(i.toDouble(), val));
          if (val > maxY) maxY = val;
        }

        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.borderDefault.withOpacity(0.5),
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
                          day.length > 5 ? day.substring(5) : day, // Show MM-DD
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
                      AppColors.neonBlue.withOpacity(0.2),
                      AppColors.neonBlue.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
