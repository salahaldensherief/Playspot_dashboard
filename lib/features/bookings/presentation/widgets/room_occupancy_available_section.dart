import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/open_time_session_dialog.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

class RoomOccupancyAvailableSection extends StatelessWidget {
  final RoomEntity room;
  final String loungeId;

  const RoomOccupancyAvailableSection({
    super.key,
    required this.room,
    required this.loungeId,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final allowOpenTimePolicy = context.select<LoginCubit, bool>(
      (c) => c.state.userLounge?.allowOpenTimeSessions ?? false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _priceRow(AppStrings.singlePriceLabel, room.pricePerHourSingle),
              const SizedBox(height: 4),
              _priceRow(AppStrings.multiPriceLabel, room.pricePerHourMulti),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        if (room.openTimeEnabled) ...[
          Tooltip(
            message: allowOpenTimePolicy
                ? ''
                : AppStrings.openTimeDisabledByPolicy,
            child: AppButton(
              text: AppStrings.openTime,
              icon: Icons.all_inclusive_rounded,
              variant: AppButtonVariant.primary,
              height: 36.h,
              onPressed: allowOpenTimePolicy
                  ? () {
                      showDialog(
                        context: context,
                        useRootNavigator: false,
                        builder: (_) => OpenTimeSessionDialog(room: room),
                      );
                    }
                  : null,
            ),
          ),
          SizedBox(height: 8.h),
        ],

        LayoutBuilder(
          builder: (context, constraints) {
            final quickBooking = AppButton(
              text: AppStrings.walkInBooking,
              icon: Icons.flash_on_rounded,
              variant: AppButtonVariant.primary,
              onPressed: () => showDialog(
                context: context,
                useRootNavigator: false,
                builder: (_) => AddBookingDialog(
                  loungeId: loungeId,
                  initialRoom: room,
                  quickMode: true,
                ),
              ),
            );
            final detailedBooking = AppButton(
              text: AppStrings.detailedBooking,
              icon: Icons.add_rounded,
              variant: AppButtonVariant.outlined,
              onPressed: () => showDialog(
                context: context,
                useRootNavigator: false,
                builder: (_) =>
                    AddBookingDialog(loungeId: loungeId, initialRoom: room),
              ),
            );
            final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
            if (constraints.maxWidth < 380 * scale) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  quickBooking,
                  const SizedBox(height: 4),
                  detailedBooking,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: quickBooking),
                const SizedBox(width: 8),
                Expanded(child: detailedBooking),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _priceRow(String label, double rate) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: AppText.body(label, color: AppColors.textSecondary)),
      const SizedBox(width: 8),
      Expanded(
        child: AppText.body(
          '${rate.toStringAsFixed(0)} ${AppStrings.egp}/${AppStrings.perHour}',
          textAlign: TextAlign.end,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}
