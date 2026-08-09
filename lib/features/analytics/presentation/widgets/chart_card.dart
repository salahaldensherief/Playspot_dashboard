import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget chart;
  final IconData actionIcon;
  final Color actionIconColor;

  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.chart,
    required this.actionIcon,
    required this.actionIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
              Icon(actionIcon, color: actionIconColor, size: 20.r),
            ],
          ),
          SizedBox(height: 32.h),
          Expanded(child: chart),
        ],
      ),
    );
  }
}

class RevenueChart extends StatelessWidget {
  const RevenueChart({super.key});

  @override
  Widget build(BuildContext context) {
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
                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                if (value.toInt() >= 0 && value.toInt() < months.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Text(
                      months[value.toInt()],
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
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
                if (value % 20000 == 0) {
                  return Text(
                    '${value.toInt()}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 45.w,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: 80000,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 45000),
              FlSpot(1, 38000),
              FlSpot(2, 42000),
              FlSpot(3, 62000),
              FlSpot(4, 55000),
              FlSpot(5, 75000),
            ],
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
  }
}

class BookingTrendsChart extends StatelessWidget {
  const BookingTrendsChart({super.key});

  @override
  Widget build(BuildContext context) {
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
                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                if (value.toInt() >= 0 && value.toInt() < months.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Text(
                      months[value.toInt()],
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
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
                if (value % 50 == 0) {
                  return Text(
                    '${value.toInt()}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 35.w,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: 200,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 120),
              FlSpot(1, 150),
              FlSpot(2, 135),
              FlSpot(3, 170),
              FlSpot(4, 155),
              FlSpot(5, 190),
            ],
            isCurved: true,
            color: AppColors.neonPurple,
            barWidth: 3.w,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}
