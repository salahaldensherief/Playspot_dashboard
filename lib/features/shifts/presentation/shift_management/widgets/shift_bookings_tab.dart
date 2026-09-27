import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../shift_cubit.dart';
import '../shift_state.dart';

class ShiftBookingsTab extends StatelessWidget {
  const ShiftBookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftCubit, ShiftState>(
      buildWhen: (prev, curr) => prev.shiftBookings != curr.shiftBookings,
      builder: (context, state) {
        if (state.shiftBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border_rounded, size: 48.r, color: AppColors.textSecondary),
                SizedBox(height: 12.h),
                AppText.body(AppStrings.noLinkedBookings, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: state.shiftBookings.length,
          separatorBuilder: (context, index) => Divider(color: AppColors.borderDefault, height: 1.h),
          itemBuilder: (context, index) {
            final b = state.shiftBookings[index];
            final customerName = b['profiles']?['full_name']?.toString() ?? AppStrings.walkInCustomer;
            final roomName = b['rooms']?['name']?.toString() ?? AppStrings.rooms;
            final price = (b['total_price'] ?? b['price'] ?? 0).toDouble();

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.neonBlue.withValues(alpha: 0.15),
                child: Icon(Icons.videogame_asset, color: AppColors.neonBlue, size: 20.r),
              ),
              title: Text('$customerName ($roomName)', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${AppStrings.statusLabel(b['status']?.toString() ?? "N/A")} | ${AppStrings.paymentStatusLabel(b['payment_status']?.toString() ?? "N/A")}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              trailing: Text(
                '${price.toStringAsFixed(2)} ${AppStrings.egp}',
                style: const TextStyle(
                  color: AppColors.neonBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
