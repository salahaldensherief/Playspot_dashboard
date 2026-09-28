import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/core/responsive/app_breakpoints.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/login/login_cubit.dart';
import '../../../auth/presentation/login/login_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<LoginCubit>().state;
      if (authState.status == LoginStatus.authenticated && authState.user != null) {
        _initWatchingBookings(authState.user!);
      }
    });
  }

  void _initWatchingBookings(UserEntity user) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.isExpired) return;

    if (user.isSuperAdmin) {
      context.read<BookingCubit>().startWatchingBookings();
    } else if (user.loungeId != null && user.loungeId!.isNotEmpty) {
      context.read<BookingCubit>().startWatchingBookings(loungeId: user.loungeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (prev, curr) {
        final wasAuth = prev.status == LoginStatus.authenticated;
        final isAuth = curr.status == LoginStatus.authenticated;
        return (!wasAuth && isAuth) || (prev.user?.loungeId != curr.user?.loungeId);
      },
      listener: (context, state) {
        if (state.status == LoginStatus.authenticated && state.user != null) {
          _initWatchingBookings(state.user!);
        }
      },
      child: DashboardLayout(
        title: AppStrings.monthlyReports,
        activeRoute: 'Reports',
        child: BlocBuilder<BookingCubit, BookingState>(
          buildWhen: (previous, current) => 
              previous.status != current.status || 
              previous.bookings != current.bookings,
          builder: (context, state) {
            final monthlyBookings = state.bookings.where((b) => 
              b.date.month == _selectedDate.month && 
              b.date.year == _selectedDate.year &&
              b.status == BookingStatus.completed
            ).toList();

            double totalRevenue = 0;
            for (var b in monthlyBookings) {
              totalRevenue += b.totalPrice;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 32.h),
                _buildStatsGrid(monthlyBookings.length, totalRevenue),
                SizedBox(height: 32.h),
                _buildHistoryTable(monthlyBookings),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.heading(DateFormat('MMMM yyyy').format(_selectedDate), fontSize: 22.sp),
          SizedBox(height: 4.h),
          AppText.body(AppStrings.selectMonth, fontSize: 13.sp),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: AppStrings.selectMonth,
              icon: Icons.calendar_month,
              variant: AppButtonVariant.primary,
              onPressed: () => _selectDate(context),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.heading(DateFormat('MMMM yyyy').format(_selectedDate), fontSize: 28.sp),
            AppText.body(AppStrings.selectMonth),
          ],
        ),
        AppButton(
          text: AppStrings.selectMonth,
          icon: Icons.calendar_month,
          variant: AppButtonVariant.primary,
          onPressed: () => _selectDate(context),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(int count, double revenue) {
    final isMobile = AppBreakpoints.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          _buildStatCard(AppStrings.totalBookings, count.toString(), Icons.confirmation_number_outlined, AppColors.neonBlue),
          SizedBox(height: 12.h),
          _buildStatCard(AppStrings.totalRevenue, "${revenue.toStringAsFixed(0)} ${AppStrings.egp}", Icons.payments_outlined, AppColors.success),
        ],
      );
    }

    return Row(
      children: [
        _buildStatCard(AppStrings.totalBookings, count.toString(), Icons.confirmation_number_outlined, AppColors.neonBlue),
        SizedBox(width: 20.w),
        _buildStatCard(AppStrings.totalRevenue, "${revenue.toStringAsFixed(0)} ${AppStrings.egp}", Icons.payments_outlined, AppColors.success),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12.r)),
              child: Icon(icon, color: color, size: 28.r),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(label, color: AppColors.textSecondary, overflow: TextOverflow.ellipsis),
                  AppText.heading(value, fontSize: 24.sp, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTable(List<Booking> bookings) {
    return DataTableWidget(
      columns: [AppStrings.date, AppStrings.customerName, AppStrings.roomLabel, AppStrings.totalPrice, AppStrings.status],
      rows: bookings.map((b) => DataRow(
        cells: [
          DataCell(AppText.body(DateFormat('MMM dd').format(b.date))),
          DataCell(AppText.body(b.userName ?? AppStrings.anonymous)),
          DataCell(AppText.body(b.roomName)),
          DataCell(AppText.body("${b.totalPrice} ${AppStrings.egp}", color: AppColors.neonBlue, fontWeight: FontWeight.bold)),
          DataCell(StatusBadge.success(AppStrings.completed)),
        ],
      )).toList(),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              onPrimary: Colors.black,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
