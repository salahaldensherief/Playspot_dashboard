import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuperAdminPayoutsPage extends StatefulWidget {
  const SuperAdminPayoutsPage({super.key});

  @override
  State<SuperAdminPayoutsPage> createState() => _SuperAdminPayoutsPageState();
}

class _SuperAdminPayoutsPageState extends State<SuperAdminPayoutsPage> {
  List<Map<String, dynamic>> _pendingPayouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await sl<SupabaseClient>().rpc('get_pending_payouts_overview');
      setState(() {
        _pendingPayouts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _createPayout(String loungeId, String loungeName) async {
    try {
      final result = await sl<SupabaseClient>().rpc('create_payout', params: {
        'p_lounge_id': loungeId,
        'p_period_start': '2026-01-01',
        'p_period_end': DateTime.now().toIso8601String().split('T')[0],
      });
      
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payout created for $loungeName: \$${result['amount']}')),
          );
          _fetchData();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            AppStrings.loungePayouts,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
          SizedBox(height: 32.h),
          _isLoading 
            ? const TableShimmer(columns: 4)
            : _pendingPayouts.isEmpty 
              ? Center(child: Text(AppStrings.noPendingPayouts, style: const TextStyle(color: AppColors.textSecondary)))
              : DataTableWidget(
                  columns: [AppStrings.lounges, AppStrings.pendingAmount, AppStrings.paymentsCount, AppStrings.actions],
                  rows: _pendingPayouts.map((p) => DataRow(
                    cells: [
                      DataCell(Text(p['lounge_name'], style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
                      DataCell(Text('\$${(p['pending_amount'] as num).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.neonGreen))),
                      DataCell(Text(p['pending_payments_count'].toString(), style: const TextStyle(color: AppColors.textSecondary))),
                      DataCell(
                        AppButton(
                          text: AppStrings.createPayout,
                          onPressed: () => _createPayout(p['lounge_id'], p['lounge_name']),
                        ),
                      ),
                    ],
                  )).toList(),
                ),
        ],
      ),
    );
  }
}
