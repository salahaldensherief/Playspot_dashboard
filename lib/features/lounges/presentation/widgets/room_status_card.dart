import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';

class RoomStatusCard extends StatefulWidget {
  const RoomStatusCard({super.key});

  @override
  State<RoomStatusCard> createState() => _RoomStatusCardState();
}

class _RoomStatusCardState extends State<RoomStatusCard> {
  final List<Map<String, dynamic>> _rooms = [
    {'name': 'VIP 01', 'status': 'available'},
    {'name': 'VIP 02', 'status': 'available'},
    {'name': 'Room A', 'status': 'maintenance'},
    {'name': 'Room B', 'status': 'available'},
    {'name': 'Hall A', 'status': 'available'},
  ];

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
          Text(
            'Room Availability Control',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rooms.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.divider),
            itemBuilder: (context, index) {
              final room = _rooms[index];
              final isAvailable = room['status'] == 'available';
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    room['name'],
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14.sp),
                  ),
                  Row(
                    children: [
                      Text(
                        isAvailable ? 'Online' : 'Under Maintenance',
                        style: TextStyle(
                          color: isAvailable ? AppColors.success : AppColors.warning,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Switch(
                        value: isAvailable,
                        activeColor: AppColors.neonBlue,
                        inactiveThumbColor: AppColors.textMuted,
                        onChanged: (val) {
                          setState(() {
                            _rooms[index]['status'] = val ? 'available' : 'maintenance';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
