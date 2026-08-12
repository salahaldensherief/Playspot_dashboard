import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import '../widgets/lounge_profile_view.dart';

class LoungeProfilePage extends StatelessWidget {
  const LoungeProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: AppStrings.loungeProfile,
      activeRoute: AppStrings.myProfile,
      child: const LoungeProfileView(),
    );
  }
}
