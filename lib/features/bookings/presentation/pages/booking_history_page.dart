import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import '../../../auth/presentation/login/login_cubit.dart';
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
      final user = context.read<LoginCubit>().state.user;
      context.read<BookingCubit>().startWatchingBookings(loungeId: user?.loungeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
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
    );
  }

  Widget _buildHeader(BuildContext context) {
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
        ElevatedButton.icon(
          onPressed: () => _selectDate(context),
          icon: const Icon(Icons.calendar_month),
          label: Text(AppStrings.selectMonth),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonBlue,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(int count, double revenue) {
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
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
              child: Icon(icon, color: color, size: 28.r),
            ),
            SizedBox(width: 20.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.body(label, color: AppColors.textSecondary),
                AppText.heading(value, fontSize: 24.sp, color: color),
              ],
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
            dialogBackgroundColor: AppColors.cardBackground,
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
