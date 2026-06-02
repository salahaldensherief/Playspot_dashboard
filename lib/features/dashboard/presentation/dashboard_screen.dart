import 'package:flutter/material.dart';
import '../../auth/domain/entities/admin_entity.dart';
import '../../../art_core/app_strings.dart';
import '../../../art_core/theme/app_colors.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';
import 'widgets/stat_card.dart';
import 'widgets/chart_card.dart';
import 'widgets/top_lounges_card.dart';

class DashboardScreen extends StatelessWidget {
  final AdminRole role;
  
  const DashboardScreen({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Row(
        children: [
          const DashboardSidebar(activeRoute: AppStrings.dashboard),
          Expanded(
            child: Column(
              children: [
                const DashboardTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.dashboard,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          AppStrings.dashboardSubtitle,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Stat Cards Grid
                        const Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: AppStrings.totalLounges,
                                value: '24',
                                trend: '+3',
                                icon: Icons.apartment,
                                iconColor: AppColors.neonBlue,
                              ),
                            ),
                            SizedBox(width: 24),
                            Expanded(
                              child: StatCard(
                                title: AppStrings.totalUsers,
                                value: '8,542',
                                trend: '+12.5%',
                                icon: Icons.groups_outlined,
                                iconColor: AppColors.neonPurple,
                              ),
                            ),
                            SizedBox(width: 24),
                            Expanded(
                              child: StatCard(
                                title: AppStrings.activeBookings,
                                value: '342',
                                trend: '+8.2%',
                                icon: Icons.calendar_today,
                                iconColor: AppColors.neonCyan,
                              ),
                            ),
                            SizedBox(width: 24),
                            Expanded(
                              child: StatCard(
                                title: AppStrings.monthlyRevenue,
                                value: '\$67,000',
                                trend: '+15.3%',
                                icon: Icons.attach_money,
                                iconColor: AppColors.neonGreen,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Charts Row
                        const SizedBox(
                          height: 400,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ChartCard(
                                  title: AppStrings.revenueOverview,
                                  subtitle: AppStrings.revenueOverviewSubtitle,
                                  actionIcon: Icons.trending_up,
                                  actionIconColor: AppColors.success,
                                  chart: RevenueChart(),
                                ),
                              ),
                              SizedBox(width: 24),
                              Expanded(
                                flex: 2,
                                child: ChartCard(
                                  title: AppStrings.bookingTrends,
                                  subtitle: AppStrings.bookingTrendsSubtitle,
                                  actionIcon: Icons.show_chart,
                                  actionIconColor: AppColors.neonPurple,
                                  chart: BookingTrendsChart(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Bottom Section
                        const TopLoungesCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
