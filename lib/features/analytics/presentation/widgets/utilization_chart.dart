import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_state.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';

class UtilizationChart extends StatelessWidget {
  const UtilizationChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomCubit, RoomState>(
      buildWhen: (prev, curr) => prev.rooms != curr.rooms,
      builder: (context, roomState) {
        return BlocBuilder<DashboardCubit, DashboardState>(
          buildWhen: (prev, curr) => prev.activeSessionsList != curr.activeSessionsList,
          builder: (context, dashboardState) {
            final rooms = roomState.rooms;

            if (rooms.isEmpty) {
              return Center(
                child: Text(
                  AppStrings.noResultsMatching.replaceFirst("\"{}\"", ""),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            final activeRoomIds = dashboardState.activeSessionsList
                .map((s) => s.roomId)
                .where((id) => id.isNotEmpty)
                .toSet();

            final colors = [
              AppColors.neonBlue,
              AppColors.neonPurple,
              AppColors.neonCyan,
              AppColors.neonGreen,
              AppColors.warning,
            ];

            final barGroups = <BarChartGroupData>[];
            final roomNames = <String>[];

            for (int i = 0; i < rooms.length; i++) {
              final room = rooms[i];
              roomNames.add(room.nameEn.isNotEmpty ? room.nameEn : room.nameAr);

              final isOccupied = activeRoomIds.contains(room.id);
              final double utilizationRate = isOccupied ? 100.0 : 0.0;
              final color = colors[i % colors.length];

              barGroups.add(_makeGroup(i, utilizationRate, color));
            }

            return RepaintBoundary(
              child: BarChart(
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
                          final index = value.toInt();
                          if (index >= 0 && index < roomNames.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Text(
                                roomNames[index],
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            );
          },
        );
      },
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
            color: color.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }
}
