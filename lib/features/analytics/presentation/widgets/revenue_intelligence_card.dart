import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/analytics/domain/entities/dashboard_booking_insights.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';

class RevenueIntelligenceCard extends StatelessWidget {
  const RevenueIntelligenceCard({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<BookingCubit, BookingState>(
    buildWhen: (previous, current) =>
        previous.bookings != current.bookings ||
        previous.status != current.status,
    builder: (context, state) {
      final insights = DashboardBookingInsights(
        state.bookings,
        day: DateTime.now(),
      );
      final unavailable = 'dashboard_metric_unavailable'.tr();
      final metrics = [
        (
          AppStrings.avgSessionSpend,
          insights.averageSpend == null
              ? unavailable
              : '${insights.averageSpend!.toStringAsFixed(0)} EGP',
          Icons.payments_outlined,
        ),
        (
          AppStrings.avgSessionDuration,
          insights.averageHours == null
              ? unavailable
              : '${insights.averageHours!.toStringAsFixed(1)} ${AppStrings.hoursAbbr}',
          Icons.timer_outlined,
        ),
        (
          AppStrings.canteenAttachRate,
          insights.canteenAttachPercent == null
              ? unavailable
              : '${insights.canteenAttachPercent!.round()}%',
          Icons.fastfood_outlined,
        ),
        (
          AppStrings.repeatGamers,
          insights.repeatPercent == null
              ? unavailable
              : '${insights.repeatPercent!.round()}%',
          Icons.people_outline,
        ),
      ];
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.revenueIntelligence,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (state.status == BookingStatusState.failure)
              Text(
                'dashboard_data_unavailable'.tr(),
                style: const TextStyle(color: AppColors.warning),
              )
            else if (state.status == BookingStatusState.initial ||
                state.status == BookingStatusState.loading)
              const LinearProgressIndicator()
            else if (insights.count == 0)
              Text(
                'dashboard_no_measured_bookings'.tr(),
                style: const TextStyle(color: AppColors.textSecondary),
              )
            else ...[
              Text(
                'dashboard_measured_bookings'.tr(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
                  final columns = constraints.maxWidth >= 460 * scale ? 2 : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final (label, value, icon) in metrics)
                        SizedBox(
                          width: width,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.scaffoldBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(icon, color: AppColors.neonBlue, size: 20),
                                const SizedBox(height: 8),
                                Text(
                                  label,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  value,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      );
    },
  );
}
