import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final List<Map<String, String>> _mockCategories = [
    {'name_ar': 'ألعاب كونسول', 'name_en': 'Console Gaming', 'icon': 'sports_esports'},
    {'name_ar': 'أجهزة كمبيوتر', 'name_en': 'PC Gaming', 'icon': 'computer'},
    {'name_ar': 'واقع افتراضي', 'name_en': 'Virtual Reality', 'icon': 'vrpano'},
    {'name_ar': 'بلياردو', 'name_en': 'Billiards', 'icon': 'sports_basketball'},
  ];

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => const _CategoryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.categories,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              AppButton(
                text: 'Add Category',
                onPressed: _showAddCategoryDialog,
                icon: Icons.add,
              ),
            ],
          ),
          SizedBox(height: 32.h),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 24.w,
                mainAxisSpacing: 24.h,
                childAspectRatio: 2.5,
              ),
              itemCount: _mockCategories.length,
              itemBuilder: (context, index) {
                final category = _mockCategories[index];
                return _CategoryCard(category: category);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, String> category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.neonBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.category, color: AppColors.neonBlue, size: 24.r),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category['name_en']!,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                Text(
                  category['name_ar']!,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            onPressed: () => _showEditCategoryDialog(context, category),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _confirmDelete(context, category['name_en']!),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Map<String, String> category) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(initialData: category),
    );
  }

  void _confirmDelete(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Delete Category', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel)),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final Map<String, String>? initialData;
  const _CategoryDialog({this.initialData});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late TextEditingController _nameAr;
  late TextEditingController _nameEn;
  late TextEditingController _iconKey;

  @override
  void initState() {
    super.initState();
    _nameAr = TextEditingController(text: widget.initialData?['name_ar']);
    _nameEn = TextEditingController(text: widget.initialData?['name_en']);
    _iconKey = TextEditingController(text: widget.initialData?['icon']);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 500.w,
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialData == null ? 'Add New Category' : 'Edit Category', 
              style: TextStyle(color: AppColors.textPrimary, fontSize: 20.sp, fontWeight: FontWeight.bold)
            ),
            SizedBox(height: 24.h),
            AppTextField(
              label: AppStrings.nameAr,
              controller: _nameAr,
              hintText: 'مثال: ألعاب كونسول',
              validator: AppValidator.validateRequired,
            ),
            SizedBox(height: 16.h),
            AppTextField(
              label: AppStrings.nameEn,
              controller: _nameEn,
              hintText: 'e.g. Console Gaming',
              validator: AppValidator.validateRequired,
            ),
            SizedBox(height: 16.h),
            AppTextField(
              label: 'Icon Key',
              controller: _iconKey,
              hintText: 'e.g. sports_esports',
            ),
            SizedBox(height: 32.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  text: AppStrings.cancel,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 16.w),
                AppButton(
                  text: 'Save Category',
                  onPressed: () {
                    // Update/Save logic here
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
