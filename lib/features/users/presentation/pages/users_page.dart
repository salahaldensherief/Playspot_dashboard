import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import '../widgets/users_header.dart';
import '../widgets/users_table_section.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: AppStrings.userLabel,
      activeRoute: 'Users',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const UsersHeader(),
          SizedBox(height: 32.h),
          const UsersTableSection(),
        ],
      ),
    );
  }
}
