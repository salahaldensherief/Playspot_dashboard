import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';

class UtilizationChart extends StatelessWidget {
  const UtilizationChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const rooms = ['VIP 1', 'VIP 2', 'Rm A', 'Rm B', 'Hall'];
                if (value.toInt() >= 0 && value.toInt() < rooms.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(rooms[value.toInt()], style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30.w,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeGroup(0, 85, AppColors.neonBlue),
          _makeGroup(1, 65, AppColors.neonPurple),
          _makeGroup(2, 45, AppColors.neonCyan),
          _makeGroup(3, 90, AppColors.neonGreen),
          _makeGroup(4, 30, AppColors.warning),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16.w,
          borderRadius: BorderRadius.circular(4.r),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: color.withOpacity(0.05),
          ),
        ),
      ],
    );
  }
}
