import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/core/utils/item_name_resolver.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import '../../../../art_core/widgets/status_badge.dart';
import '../../../analytics/presentation/dashboard_cubit.dart';
import '../../../auth/presentation/login/login_cubit.dart';
import '../../../lounges/domain/entities/extra_entity.dart';
import '../../../lounges/presentation/cubit/extras_cubit.dart';
import '../../domain/entities/booking.dart';
import '../cubit/booking_cubit.dart';
import 'add_extras_dialog.dart';
import 'booking_products_preview.dart';
import 'customer_visit_badge.dart';
import 'radial_countdown_ring.dart';
import 'room_discount_dialog.dart';
import 'session_ticker.dart';
import 'station_control_drawer.dart';
import 'swap_room_dialog.dart';

/// Interactive UI Card Widget for live active gaming sessions.
/// Listens to global SessionTickerScope without running individual timers.
class LiveSessionCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onEndSession;
  final VoidCallback? onExtendSession;
  final Function(int additionalMinutes)? onExtendMinutes;
  final double? width;

  const LiveSessionCard({
    super.key,
    required this.booking,
    this.onEndSession,
    this.onExtendSession,
    this.onExtendMinutes,
    this.width,
  });

  @override
  State<LiveSessionCard> createState() => _LiveSessionCardState();
}

class _LiveSessionCardState extends State<LiveSessionCard> {
  bool _isHovered = false;

  Duration get _remainingDuration => widget.booking.remainingDuration();
  bool get _isExpired => widget.booking.isSessionExpired();

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatTime12Hour(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, hour, minute);
        return DateFormat('hh:mm a').format(dt);
      }
      return timeStr;
    } catch (e) {
      return timeStr;
    }
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.abs();
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    if (totalSeconds >= 3600) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _openStationControl() {
    StationControlDrawer.show(
      context,
      booking: widget.booking,
      onEndSession: widget.onEndSession,
    );
  }

  @override
  Widget build(BuildContext context) {
    SessionTickerScope.nowOf(context);

    final booking = widget.booking;
    final isExpired = _isExpired;
    final remaining = _remainingDuration;
    final isAlmostDone = !isExpired && !booking.isOpenEnded && remaining.inMinutes <= 5;

    final Color accent = isExpired
        ? AppColors.danger
        : (isAlmostDone ? AppColors.warning : AppColors.success);

    return MouseRegion(
      onEnter: (_) {
        if (mounted && !_isHovered) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovered = true);
          });
        }
      },
      onExit: (_) {
        if (mounted && _isHovered) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovered = false);
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: widget.width ?? 320.w,
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: accent.withValues(alpha: _isHovered || isExpired ? 0.9 : 0.55),
            width: _isHovered || isExpired ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: _isHovered ? 0.22 : 0.12),
              blurRadius: _isHovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.r),
          child: Material(
            color: Colors.transparent,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final content = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1) Header
                    _buildHeader(accent),

                    Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2) Customer Row
                          _buildCustomerRow(booking),
                          SizedBox(height: 12.h),

                          // 3) Timer Box (Hero)
                          _buildTimerBox(
                            accent: accent,
                            isExpired: isExpired,
                            remaining: remaining,
                          ),
                          SizedBox(height: 10.h),

                          // 4) Quick Time Extension Bar
                          _buildQuickExtendRow(),

                          // 5) Canteen & Requests
                          BookingProductsPreview(booking: booking),
                          _buildActiveSessionRequests(context),

                          SizedBox(height: 12.h),
                          Container(height: 1, color: AppColors.borderDefault.withValues(alpha: 0.6)),
                          SizedBox(height: 10.h),

                          // 6) Financial Row
                          _buildFinancialRow(booking),
                          SizedBox(height: 14.h),

                          // 7) Action Toolbar
                          _buildActions(context),
                        ],
                      ),
                    ),
                  ],
                );

                if (constraints.hasBoundedHeight) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(child: content),
                    ),
                  );
                }
                return content;
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return Container(
      color: accent.withValues(alpha: 0.08),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.sports_esports_rounded, size: 16.r, color: accent),
                SizedBox(width: 6.w),
                Flexible(
                  child: AppText.subHeading(
                    widget.booking.roomName,
                    fontSize: 13.sp,
                    color: AppColors.textPrimary,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 6.w),
                _ToolButton(
                  icon: Icons.swap_horiz_rounded,
                  tooltip: AppStrings.swapRoom,
                  color: AppColors.neonBlue,
                  onTap: () => _showSwapRoomDialog(context),
                ),
                SizedBox(width: 4.w),
                _ToolButton(
                  icon: Icons.tune_rounded,
                  tooltip: AppStrings.stationControlDrawer,
                  color: AppColors.neonPurple,
                  onTap: _openStationControl,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          StatusBadge.success(AppStrings.inProgress.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildCustomerRow(Booking booking) {
    final hasPhone = booking.userPhone != null && booking.userPhone!.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.neonBlue.withValues(alpha: 0.75),
                AppColors.neonPurple.withValues(alpha: 0.75),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            _getInitials(booking.userName),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: AppText.subHeading(
                      booking.userName ?? AppStrings.anonymous,
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  CustomerVisitBadge(visitNumber: booking.visitNumber),
                ],
              ),
              if (hasPhone) ...[
                SizedBox(height: 2.h),
                AppText.body(
                  booking.userPhone!,
                  fontSize: 11.sp,
                  color: AppColors.neonBlue,
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerBox({
    required Color accent,
    required bool isExpired,
    required Duration remaining,
  }) {
    final booking = widget.booking;
    final formattedTime = _formatDuration(remaining);
    final String durationHrs = (booking.durationMinutes / 60.0).toStringAsFixed(1).replaceAll('.0', '');

    return InkWell(
      onTap: _openStationControl,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            RadialCountdownRing(
              totalDuration: Duration(minutes: booking.durationMinutes),
              remainingDuration: remaining,
              isExpired: isExpired,
              isOpenEnded: booking.isOpenEnded,
              showText: false,
              size: 38.0,
              strokeWidth: 3.5,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(
                    isExpired ? AppStrings.timeExpired : AppStrings.remainingTime,
                    fontSize: 11.5.sp,
                    color: isExpired ? AppColors.danger : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  AppText.body(
                    '${_formatTime12Hour(booking.startTime)} ($durationHrs ${AppStrings.hours})',
                    fontSize: 10.5.sp,
                    color: AppColors.textMuted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 130.w),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AppText.subHeading(
                  isExpired ? '-$formattedTime' : formattedTime,
                  fontSize: 22.sp,
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickExtendRow() {
    return Row(
      children: [
        Expanded(child: _ExtendChip(label: '+15m', onTap: () => _handleExtendMinutes(context, 15))),
        SizedBox(width: 6.w),
        Expanded(child: _ExtendChip(label: '+30m', onTap: () => _handleExtendMinutes(context, 30))),
        SizedBox(width: 6.w),
        Expanded(child: _ExtendChip(label: '+1h', onTap: () => _handleExtendMinutes(context, 60))),
      ],
    );
  }

  Widget _buildFinancialRow(Booking booking) {
    final hasDiscount = (booking.discountAmount ?? 0) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(
          AppStrings.totalPrice,
          fontSize: 10.5.sp,
          color: AppColors.textMuted,
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Flexible(
              child: AppText.subHeading(
                '${booking.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}',
                color: AppColors.neonBlue,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                maxLines: 1,
              ),
            ),
            if (hasDiscount) ...[
              SizedBox(width: 6.w),
              _Pill(
                label: '-${booking.discountAmount!.toStringAsFixed(0)} ${AppStrings.egp}',
                color: AppColors.warning,
              ),
            ],
            SizedBox(width: 6.w),
            _ToolButton(
              icon: Icons.local_offer_outlined,
              tooltip: AppStrings.applyDiscount,
              color: AppColors.warning,
              onTap: () => _showDiscountDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final double h = 36.h;

    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: AppStrings.endSession,
            icon: Icons.stop_circle_outlined,
            variant: AppButtonVariant.outlined,
            height: h,
            onPressed: () => _handleEndSession(context),
          ),
        ),
        SizedBox(width: 6.w),
        Tooltip(
          message: AppStrings.addExtrasToSession,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: () => _showAddExtrasDialog(context),
            child: Container(
              width: h,
              height: h,
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.35)),
              ),
              child: Icon(Icons.add_shopping_cart, size: 17.r, color: AppColors.neonCyan),
            ),
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: AppButton(
            text: AppStrings.extendTime,
            icon: Icons.add_alarm_rounded,
            variant: AppButtonVariant.primary,
            height: h,
            onPressed: () => _handleExtendSession(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSessionRequests(BuildContext context) {
    return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
      builder: (context, requestsState) {
        final sessionRequests = requestsState.requests.where((r) {
          if (r.isAttended) return false;
          final matchBooking = r.bookingId != null && r.bookingId == widget.booking.id;
          final matchRoom = r.roomId != null && r.roomId == widget.booking.roomId;
          return matchBooking || matchRoom;
        }).toList();

        if (sessionRequests.isEmpty) return const SizedBox.shrink();

        final extrasCubit = context.watch<ExtrasCubit?>();
        final List<ExtraEntity> availableExtras = extrasCubit?.state.extras ?? [];

        return Container(
          margin: EdgeInsets.only(top: 8.h),
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 14.r),
                  SizedBox(width: 4.w),
                  AppText.body(
                    '${AppStrings.sessionRequests} (${sessionRequests.length})',
                    fontSize: 11.sp,
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              ...sessionRequests.take(2).map((req) {
                String displayText = '';
                if (req.isCanteenOrder && req.canteenItems.isNotEmpty) {
                  final itemsText = req.canteenItems.map((it) {
                    final qty = it['quantity'] ?? it['qty'] ?? 1;
                    final name = resolveItemName(it, availableExtras);
                    return '${qty}x $name';
                  }).join(', ');
                  displayText = '${AppStrings.canteenOrderLabel}: $itemsText';
                } else {
                  displayText = req.bodyAr.isNotEmpty ? req.bodyAr : req.titleAr;
                }

                if (req.metadata.notes != null && req.metadata.notes!.isNotEmpty) {
                  displayText += ' (ملاحظة: ${req.metadata.notes})';
                }

                return Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppText.body(
                          '• $displayText',
                          fontSize: 11.sp,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      InkWell(
                        borderRadius: BorderRadius.circular(6.r),
                        onTap: () {
                          context.read<ClientRequestsCubit>().markAsAttended(
                                req.id,
                                isCanteenOrder: req.isCanteenOrder,
                              );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            AppStrings.done,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showDiscountDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => RoomDiscountDialog(
        roomName: widget.booking.roomName.isNotEmpty ? widget.booking.roomName : AppStrings.roomLabel,
        currentPrice: widget.booking.totalPrice,
        onApplyDiscount: (amount, percent, reason) {
          context.read<BookingCubit>().confirmCashPayment(
                widget.booking.id,
                discountAmount: amount,
                discountPercentage: percent,
                discountReason: reason,
              );
        },
      ),
    );
  }

  void _showSwapRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (diagContext) => SwapRoomDialog(
        bookingId: widget.booking.id,
        currentRoomId: widget.booking.roomId,
      ),
    );
  }

  void _showAddExtrasDialog(BuildContext context) {
    final loginState = context.read<LoginCubit>().state;
    final userLoungeId = loginState.user?.loungeId ?? loginState.userLounge?.id;
    final cleanUserLoungeId = (userLoungeId != null && userLoungeId.trim().isNotEmpty) ? userLoungeId.trim() : null;
    final loungeId = cleanUserLoungeId ?? widget.booking.loungeId;
    final dashboardCubit = context.read<DashboardCubit>();

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (diagContext) => AddExtrasDialog(
        bookingId: widget.booking.id,
        loungeId: loungeId,
        onConfirm: (extras, totalCost) async {
          final success = await dashboardCubit.addExtrasToSession(widget.booking.id, extras, totalCost);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? AppStrings.extrasAddedSuccess : AppStrings.actionFailed),
                backgroundColor: success ? AppColors.success : AppColors.danger,
              ),
            );
          }
        },
      ),
    );
  }

  void _handleEndSession(BuildContext context) {
    if (widget.onEndSession != null) {
      widget.onEndSession!();
      return;
    }

    final dashboardCubit = context.read<DashboardCubit>();
    final bookingCubit = context.read<BookingCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Row(
          children: [
            const Icon(Icons.stop_circle, color: AppColors.danger),
            SizedBox(width: 8.w),
            Expanded(
              child: AppText.subHeading(
                AppStrings.confirmEndSession,
                color: AppColors.danger,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
        content: AppText.body(
          AppStrings.confirmEndSessionMessage,
          fontSize: 13.sp,
          color: AppColors.textPrimary,
        ),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          AppButton(
            text: AppStrings.endSession,
            variant: AppButtonVariant.danger,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await dashboardCubit.endSession(widget.booking.id);
              if (!success) {
                await bookingCubit.changeBookingStatus(widget.booking.id, BookingStatus.completed);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.sessionEndedSuccess),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleExtendSession(BuildContext context) {
    if (widget.onExtendSession != null) {
      widget.onExtendSession!();
      return;
    }

    int selectedMinutes = 30;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogInnerContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          title: Row(
            children: [
              const Icon(Icons.add_alarm, color: AppColors.neonBlue),
              SizedBox(width: 8.w),
              Expanded(
                child: AppText.subHeading(
                  AppStrings.extendTime,
                  color: AppColors.neonBlue,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(
                '${widget.booking.roomName} - ${widget.booking.userName ?? AppStrings.anonymous}',
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                children: [30, 60, 90, 120].map((mins) {
                  final isSelected = selectedMinutes == mins;
                  return ChoiceChip(
                    label: AppText.body(
                      '+$mins ${AppStrings.minutesUnit}',
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12.sp,
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.neonBlue,
                    backgroundColor: AppColors.cardBackground,
                    onSelected: (selected) {
                      if (selected) {
                        setDialogState(() {
                          selectedMinutes = mins;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            AppButton(
              text: AppStrings.cancel,
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            AppButton(
              text: AppStrings.extendTime,
              variant: AppButtonVariant.primary,
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _handleExtendMinutes(context, selectedMinutes);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExtendMinutes(BuildContext context, int minutes) async {
    if (widget.onExtendMinutes != null) {
      widget.onExtendMinutes!(minutes);
      return;
    }

    final dashboardCubit = context.read<DashboardCubit>();
    final success = await dashboardCubit.extendSession(widget.booking.id, minutes);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.timeExtendedSuccess),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      final errorMsg = dashboardCubit.state.errorMessage ?? AppStrings.extendFallbackError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 15.r, color: color),
        ),
      ),
    );
  }
}

class _ExtendChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ExtendChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 7.h),
        decoration: BoxDecoration(
          color: AppColors.neonBlue.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.neonBlue,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: AppText.body(
        label,
        fontSize: 10.5.sp,
        color: color,
        fontWeight: FontWeight.w600,
        maxLines: 1,
      ),
    );
  }
}
