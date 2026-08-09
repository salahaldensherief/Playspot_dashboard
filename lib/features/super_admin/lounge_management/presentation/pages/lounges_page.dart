import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_sidebar.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_top_bar.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import '../cubit/lounge_cubit.dart';
import '../widgets/add_lounge_dialog.dart';

class LoungesPage extends StatelessWidget {
  const LoungesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LoungeCubit>()..fetchLounges(),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Row(
          children: [
            const DashboardSidebar(activeRoute: AppStrings.lounges),
            Expanded(
              child: Column(
                children: [
                  const DashboardTopBar(title: 'Lounge Management'),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(32.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          SizedBox(height: 32.h),
                          _buildLoungesGrid(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lounges',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Manage your gaming locations, rooms, and activities',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const AddLoungeDialog(),
            );
          },
          icon: const Icon(Icons.add, color: Colors.black),
          label: const Text('Add New Lounge', style: TextStyle(color: Colors.black)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonPurple,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        ),
      ],
    );
  }

  Widget _buildLoungesGrid() {
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
                Text('No lounges found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp)),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 24.w,
            mainAxisSpacing: 24.h,
            childAspectRatio: 1.1,
          ),
          itemCount: lounges.length,
          itemBuilder: (context, index) {
            final lounge = lounges[index];
            return _buildLoungeCard(
              lounge.name,
              lounge.location,
              '8 Rooms', // Mock
              '24/7',    // Mock
              lounge.isOpen,
            );
          },
        );
      },
    );
  }

  Widget _buildLoungeCard(String name, String location, String rooms, String hours, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 120.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                  gradient: LinearGradient(
                    colors: [AppColors.neonBlue.withOpacity(0.3), AppColors.neonPurple.withOpacity(0.3)],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.business, color: Colors.white.withOpacity(0.5), size: 48.r),
                ),
              ),
              Positioned(
                top: 12.h,
                right: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success.withOpacity(0.2) : AppColors.danger.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(color: isActive ? AppColors.success : AppColors.danger),
                  ),
                  child: Text(
                    isActive ? 'OPEN' : 'CLOSED',
                    style: TextStyle(
                      color: isActive ? AppColors.success : AppColors.danger,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 14.r),
                    SizedBox(width: 4.w),
                    Expanded(child: Text(location, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp))),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(Icons.meeting_room_outlined, rooms),
                    _buildInfoItem(Icons.access_time, hours),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderDefault),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                        child: Text('Edit Info', style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp)),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonBlue.withOpacity(0.1),
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                        child: Text('Manage', style: TextStyle(color: AppColors.neonBlue, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 16.r),
        SizedBox(width: 6.w),
        Text(text, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
      ],
    );
  }
}
