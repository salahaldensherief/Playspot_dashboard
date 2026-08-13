import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class LoungeAdminPayoutsPage extends StatefulWidget {
  const LoungeAdminPayoutsPage({super.key});

  @override
  State<LoungeAdminPayoutsPage> createState() => _LoungeAdminPayoutsPageState();
}

class _LoungeAdminPayoutsPageState extends State<LoungeAdminPayoutsPage> {
  List<Map<String, dynamic>> _payouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPayouts();
  }

  Future<void> _fetchPayouts() async {
    final loungeId = context.read<LoginCubit>().state.user?.loungeId;
    if (loungeId == null) return;

    try {
      final response = await sl<SupabaseClient>()
          .from('payouts')
          .select()
          .eq('lounge_id', loungeId)
          .order('created_at', ascending: false);
      
      setState(() {
        _payouts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.myPayoutsHistory,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
          SizedBox(height: 32.h),
          _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _payouts.isEmpty 
              ? Center(child: Text(AppStrings.noPayoutHistoryFound, style: const TextStyle(color: AppColors.textSecondary)))
              : DataTableWidget(
                  columns: [AppStrings.date, AppStrings.period, AppStrings.totalPrice, AppStrings.status, AppStrings.notes],
                  rows: _payouts.map((p) => DataRow(
                    cells: [
                      DataCell(Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(p['created_at'])), style: const TextStyle(color: AppColors.textPrimary))),
                      DataCell(Text('${p['period_start']} ${AppStrings.back} ${p['period_end']}', style: const TextStyle(color: AppColors.textSecondary))),
                      DataCell(
                        Text(
                          '\$${((p['amount'] as num?) ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.neonGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),                      DataCell(
                        p['status'] == 'paid' 
                          ? StatusBadge.success(AppStrings.paid.toUpperCase())
                          : StatusBadge.warning(AppStrings.pending.toUpperCase())
                      ),
                      DataCell(Text(p['notes'] ?? '-', style: const TextStyle(color: AppColors.textMuted))),
                    ],
                  )).toList(),
                ),
        ],
      ),
    );
  }
}
