import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../widgets/marketing_sections.dart';

class MarketingPage extends StatefulWidget {
  const MarketingPage({super.key});

  @override
  State<MarketingPage> createState() => _MarketingPageState();
}

class _MarketingPageState extends State<MarketingPage> {
  final _formKey = GlobalKey<FormState>();
  
  final List<List<Color>> _colorTemplates = [
    [AppColors.neonPurple, AppColors.neonBlue],
    [Colors.orange, Colors.red],
    [Colors.green, Colors.teal],
    [Colors.blue, Colors.indigo],
  ];

  int _selectedTemplate = 0;
  String _selectedIcon = 'Flash';
  String _selectedDeepLink = 'Specific Room';

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final isSuperAdmin = user?.isSuperAdmin ?? false;

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.marketing,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
                if (isSuperAdmin)
                  AppButton(
                    text: 'Create Global Promo',
                    onPressed: () {},
                    icon: Icons.add,
                  ),
              ],
            ),
            SizedBox(height: 32.h),
            if (isSuperAdmin) 
              _buildPromotionsList()
            else 
              _buildLoungeAdminForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoungeAdminForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PromoFormSection(
            selectedDeepLink: _selectedDeepLink,
            onDeepLinkChanged: (v) => setState(() => _selectedDeepLink = v!),
          ),
          SizedBox(height: 32.h),
          DesignStyleSection(
            colorTemplates: _colorTemplates,
            selectedTemplate: _selectedTemplate,
            onTemplateSelected: (index) => setState(() => _selectedTemplate = index),
            selectedIcon: _selectedIcon,
            onIconChanged: (v) => setState(() => _selectedIcon = v!),
          ),
          SizedBox(height: 40.h),
          AppButton(
            text: AppStrings.createPromotion,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Save logic
              }
            },
            width: 250.w,
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsList() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Promotions',
            style: TextStyle(color: AppColors.neonBlue, fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24.h),
          DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.mutedBackground),
            columns: const [
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Tag')),
              DataColumn(label: Text('Lounge')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: [
              _buildPromoRow('Weekend Special', '50% OFF', 'Nexus Gaming', 'Active'),
              _buildPromoRow('Student Deal', 'FREE Drink', 'Level Up Lounge', 'Active'),
              _buildPromoRow('New User Bonus', '10% OFF', 'Global', 'Paused'),
            ],
          ),
        ],
      ),
    );
  }

  DataRow _buildPromoRow(String title, String tag, String lounge, String status) {
    return DataRow(cells: [
      DataCell(Text(title, style: const TextStyle(color: AppColors.textPrimary))),
      DataCell(Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(color: AppColors.neonBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(4.r)),
        child: Text(tag, style: const TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold)),
      )),
      DataCell(Text(lounge, style: const TextStyle(color: AppColors.textSecondary))),
      DataCell(Text(status, style: TextStyle(color: status == 'Active' ? AppColors.success : AppColors.danger))),
      DataCell(Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20), 
            onPressed: () => _showEditPromoDialog(title),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20), 
            onPressed: () => _confirmDelete(title),
          ),
        ],
      )),
    ]);
  }

  void _showEditPromoDialog(String title) {
    // Placeholder for Edit Logic - Opens form with existing data
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Editing: $title')));
  }

  void _confirmDelete(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Delete Promotion', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Are you sure you want to delete "$title"?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              // Delete logic here
              Navigator.pop(context);
            }, 
            child: Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
