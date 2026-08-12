import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import '../../domain/entities/category_entity.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import 'category_card.dart';
import 'category_dialog.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  void _showCategoryDialog(BuildContext context, CategoryCubit cubit, {CategoryEntity? category}) {
    showDialog(
      context: context,
      builder: (diagContext) => CategoryDialog(
        category: category,
        onSave: (cat) {
          if (category == null) {
            cubit.addCategory(cat);
          } else {
            cubit.updateCategory(cat);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryCubit = context.read<CategoryCubit>();

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
                text: AppStrings.addCategory,
                onPressed: () => _showCategoryDialog(context, categoryCubit),
                icon: Icons.add,
              ),
            ],
          ),
          SizedBox(height: 32.h),
          Expanded(
            child: BlocBuilder<CategoryCubit, CategoryState>(
              builder: (context, state) {
                if (state.status == CategoryStatus.loading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
                }
                if (state.status == CategoryStatus.success) {
                  if (state.categories.isEmpty) {
                    return const Center(child: Text('No categories found', style: TextStyle(color: AppColors.textSecondary)));
                  }
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 24.w,
                      mainAxisSpacing: 24.h,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: state.categories.length,
                    itemBuilder: (context, index) {
                      final category = state.categories[index];
                      return CategoryCard(
                        category: category,
                        onEdit: () => _showCategoryDialog(context, categoryCubit, category: category),
                        onDelete: () => _confirmDelete(context, categoryCubit, category),
                      );
                    },
                  );
                }
                if (state.status == CategoryStatus.failure) {
                  return Center(child: Text(state.errorMessage ?? 'Error', style: const TextStyle(color: AppColors.danger)));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CategoryCubit cubit, CategoryEntity category) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.deleteConfirmation, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${AppStrings.deleteWarning} "${category.nameEn}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagContext), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              cubit.deleteCategory(category.id);
              Navigator.pop(diagContext);
            }, 
            child: Text(AppStrings.delete, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
