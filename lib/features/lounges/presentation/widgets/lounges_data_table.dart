import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import '../cubit/lounge_cubit.dart';

class LoungesDataTable extends StatelessWidget {
  const LoungesDataTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoungeCubit, LoungeState>(
      builder: (context, state) {
        if (state is LoungeLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
        }

        final lounges = state is LoungeLoaded ? state.lounges : [];

        if (lounges.isEmpty) {
          return Center(
            child: Column(
              children: [
                SizedBox(height: 100.h),
                Icon(Icons.business_outlined, size: 64.r, color: AppColors.textMuted),
                SizedBox(height: 16.h),
                const Text('No lounges found', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return DataTableWidget(
          columns: const [
            'Lounge Name',
            'Owner / Admin',
            'Location',
            'Price/Hr',
            'Status',
            'Actions'
          ],
          rows: lounges.map((lounge) => DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(lounge.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    Text('${lounge.availableRooms ?? 0} Rooms', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
                  ],
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(lounge.ownerName ?? 'Not Assigned', style: const TextStyle(color: AppColors.textPrimary)),
                    Text(lounge.ownerEmail ?? '-', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
                  ],
                ),
              ),
              DataCell(Text(lounge.city ?? lounge.location ?? 'N/A', style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(Text('\$${lounge.pricePerHour.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textPrimary))),
              DataCell(lounge.isOpen ? StatusBadge.success('Open') : StatusBadge.danger('Closed')),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20.r),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 20.r),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          )).toList(),
        );
      },
    );
  }
}
