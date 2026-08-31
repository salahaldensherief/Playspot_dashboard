import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import '../dashboard_cubit.dart';
import '../dashboard_state.dart';

class BookingTrendsChart extends StatelessWidget {
  const BookingTrendsChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      buildWhen: (prev, curr) => prev.revenueChart != curr.revenueChart,
      builder: (context, state) {
        if (state.revenueChart.isEmpty) {
          return const SizedBox();
        }

        final spots = <FlSpot>[];
        double maxY = 10;
        
        for (int i = 0; i < state.revenueChart.length; i++) {
          final val = (state.revenueChart[i]['bookings_count'] as num?)?.toDouble() ?? 0.0;
          spots.add(FlSpot(i.toDouble(), val));
          if (val > maxY) maxY = val;
        }

        return LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: state.revenueChart.length.toDouble() - 1,
            minY: 0,
            maxY: maxY * 1.5,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.neonPurple,
                barWidth: 2.w,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        );
      },
    );
  }
}
