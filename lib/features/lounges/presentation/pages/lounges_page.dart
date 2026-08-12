import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import '../widgets/lounges_header.dart';
import '../widgets/lounges_data_table.dart';

class LoungesPage extends StatelessWidget {
  const LoungesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: AppStrings.lounges,
      activeRoute: AppStrings.lounges,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoungesHeader(),
          SizedBox(height: 32.h),
          const LoungesDataTable(),
        ],
      ),
    );
  }
}
