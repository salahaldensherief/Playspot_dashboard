import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text.dart';
import 'live_feed_header.dart';
import '../../../../art_core/widgets/shimmer_loading.dart';
import '../../../bookings/domain/entities/booking.dart';
import '../../../bookings/presentation/cubit/booking_cubit.dart';
import '../../../bookings/presentation/cubit/booking_state.dart';
import '../../../bookings/presentation/widgets/live_session_card.dart';
import '../../../bookings/presentation/widgets/session_ticker.dart';
import '../dashboard_cubit.dart';
import '../dashboard_state.dart';
import 'active_sessions_stats_bar.dart';
import 'live_booking_item.dart';
import 'live_feed_sections.dart';
import '../../../../core/responsive/app_breakpoints.dart';

/// Refactored, high-performance Live Operations Feed displaying active gaming sessions,
/// real-time revenue stats, and incoming booking requests.
class LiveBookingsFeed extends StatefulWidget {
  const LiveBookingsFeed({super.key});

  @override
  State<LiveBookingsFeed> createState() => _LiveBookingsFeedState();
}

class _LiveBookingsFeedState extends State<LiveBookingsFeed> {
  late final SessionTickerNotifier _tickerNotifier;
  late final SessionTickerNotifier _classificationTicker;

  @override
  void initState() {
    super.initState();
    _tickerNotifier = SessionTickerNotifier();
    _classificationTicker = SessionTickerNotifier(
      interval: const Duration(seconds: 15),
    );
  }

  @override
  void dispose() {
    _tickerNotifier.dispose();
    _classificationTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SessionTickerScope(
      ticker: _tickerNotifier,
      child: AnimatedBuilder(
        animation: _classificationTicker,
        builder: (context, _) {
          final now = _tickerNotifier.now;

          return BlocBuilder<DashboardCubit, DashboardState>(
            buildWhen: (prev, curr) =>
                prev.status != curr.status ||
                prev.activeSessionsList != curr.activeSessionsList ||
                prev.activeSessionsStats != curr.activeSessionsStats,
            builder: (context, dashState) {
              return BlocBuilder<BookingCubit, BookingState>(
                buildWhen: (prev, curr) =>
                    prev.status != curr.status ||
                    prev.bookings != curr.bookings,
                builder: (context, bookingState) {
                  final List<Booking> activeSessions =
                      dashState.activeSessionsList.isNotEmpty
                          ? dashState.activeSessionsList
                              .where((b) => b.isBookingActive())
                              .toList()
                          : bookingState.bookings
                              .where((b) => b.isBookingActive())
                              .toList();

                  final needsAttentionSessions = <Booking>[];
                  final normalSessions = <Booking>[];

                  for (final session in activeSessions) {
                    final isExpired = session.isSessionExpired(now);
                    final remaining = session.remainingDuration(now);
                    final isEndingSoon =
                        !session.isOpenEnded && remaining.inMinutes <= 10;

                    if (isExpired || isEndingSoon) {
                      needsAttentionSessions.add(session);
                    } else {
                      normalSessions.add(session);
                    }
                  }

                  final stats = dashState.activeSessionsStats;
                  final double activeRevenue =
                      (stats['total_revenue'] as num?)?.toDouble() ??
                          activeSessions.fold(
                              0.0, (sum, item) => sum + item.totalPrice);
                  final int activeExtrasCount =
                      (stats['total_extras_count'] as num?)?.toInt() ??
                          activeSessions.fold(
                              0, (sum, item) => sum + item.extras.length);

                  return Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LiveFeedHeader(
                          activeCount: activeSessions.length,
                          isLoading:
                              dashState.status == FeatureStatus.loading &&
                              activeSessions.isEmpty,
                        ),
                        SizedBox(height: 16.h),

                        if (activeSessions.isNotEmpty) ...[
                          ActiveSessionsStatsBar(
                            activeCount: activeSessions.length,
                            totalRevenue: activeRevenue,
                            extrasCount: activeExtrasCount,
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const spacing = 16.0;
                              final availableWidth = constraints.maxWidth;
                              final columns = AppBreakpoints.isMobileWidth(availableWidth)
                                  ? 1
                                  : AppBreakpoints.isTabletWidth(availableWidth)
                                      ? 2
                                      : (availableWidth / 340).floor().clamp(3, 6);
                              final cardWidth =
                                  (availableWidth - spacing * (columns - 1)) / columns;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (needsAttentionSessions.isNotEmpty) ...[
                                    SizedBox(height: 20.h),
                                    LiveFeedSectionHeader(
                                      title: AppStrings.needsAttention,
                                      count: needsAttentionSessions.length,
                                      color: AppColors.danger,
                                      icon: Icons.priority_high_rounded,
                                    ),
                                    SizedBox(height: 12.h),
                                    Wrap(
                                      spacing: spacing,
                                      runSpacing: spacing,
                                      children: needsAttentionSessions
                                          .map((session) {
                                        return RepaintBoundary(
                                          child: LiveSessionCard(
                                            key: ValueKey(
                                                'dash_live_attn_${session.id}'),
                                            booking: session,
                                            width: cardWidth,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  if (normalSessions.isNotEmpty) ...[
                                    SizedBox(height: 20.h),
                                    LiveFeedSectionHeader(
                                      title: AppStrings.activeGamingSessions,
                                      count: normalSessions.length,
                                      color: AppColors.neonBlue,
                                      icon: Icons.sports_esports_rounded,
                                    ),
                                    SizedBox(height: 12.h),
                                    Wrap(
                                      spacing: spacing,
                                      runSpacing: spacing,
                                      children: normalSessions.map((session) {
                                        return RepaintBoundary(
                                          child: LiveSessionCard(
                                            key: ValueKey(
                                                'dash_live_${session.id}'),
                                            booking: session,
                                            width: cardWidth,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ] else if (dashState.status == FeatureStatus.loading) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: ShimmerLoading.rounded(
                              width: double.infinity,
                              height: 120.h,
                            ),
                          ),
                        ] else ...[
                          const EmptyActiveSessionsState(),
                        ],

                        if (bookingState.bookings.isNotEmpty) ...[
                          SizedBox(height: 24.h),
                          Divider(color: AppColors.divider),
                          SizedBox(height: 12.h),
                          AppText.subHeading(
                            AppStrings.liveBookingsFeed,
                            fontSize: 15.sp,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 12.h),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: bookingState.bookings.take(5).length,
                            separatorBuilder: (context, index) =>
                                Divider(color: AppColors.divider, height: 20.h),
                            itemBuilder: (context, index) {
                              final booking = bookingState.bookings[index];
                              return LiveBookingItem(booking: booking);
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
