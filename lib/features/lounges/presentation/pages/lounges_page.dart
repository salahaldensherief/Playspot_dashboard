import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import '../cubit/lounge_cubit.dart';
import '../widgets/lounges_header.dart';
import '../widgets/lounges_data_table.dart';

class LoungesPage extends StatefulWidget {
  const LoungesPage({super.key});

  @override
  State<LoungesPage> createState() => _LoungesPageState();
}

class _LoungesPageState extends State<LoungesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoungeCubit>().fetchLounges();
    });
  }

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
