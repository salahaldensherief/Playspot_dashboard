import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_sidebar.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_top_bar.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Row(
        children: [
          DashboardSidebar(activeRoute: AppStrings.users),
          Expanded(
            child: Column(
              children: [
                DashboardTopBar(title: AppStrings.loungeAdministrators),
                Center(
                  child: Text('${AppStrings.users} - ${AppStrings.underConstruction}', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
