import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import '../../data/entities/category_entity.dart';
import '../../data/entities/city_entity.dart';
import 'category_cubit.dart';
import 'category_state.dart';
import 'widgets/category_card.dart';
import 'widgets/category_dialog.dart';
import 'widgets/city_dialog.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  void _showCityDialog(BuildContext context, CategoryCubit cubit, {CityEntity? city}) {
    showDialog(
      context: context,
      builder: (diagContext) => CityDialog(
        city: city,
        onSave: (newCity) {
          if (city == null) {
            cubit.addCity(newCity);
          } else {
            cubit.updateCity(newCity);
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
              Row(
                children: [
                  AppButton(
                    text: AppStrings.addCity,
                    onPressed: () => _showCityDialog(context, categoryCubit),
                    icon: Icons.location_city,
                    variant: AppButtonVariant.outlined,
                  ),
                  SizedBox(width: 16.w),
                  AppButton(
                    text: AppStrings.addCategory,
                    onPressed: () => _showCategoryDialog(context, categoryCubit),
                    icon: Icons.add,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24.h),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.neonBlue,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.neonBlue,
            tabs: [
              Tab(text: AppStrings.categories),
              Tab(text: AppStrings.cities),
            ],
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoriesGrid(context, categoryCubit),
                _buildCitiesList(context, categoryCubit),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context, CategoryCubit categoryCubit) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state.status.isLoading) {
          return const GridShimmer(itemCount: 6, aspectRatio: 2.5);
        }
        if (state.status.isSuccess) {
          if (state.categories.isEmpty) {
            return Center(child: Text(AppStrings.noCategoriesFound, style: const TextStyle(color: AppColors.textSecondary)));
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
        if (state.status.isFailure) {
          return Center(child: Text(state.errorMessage ?? 'Error', style: const TextStyle(color: AppColors.danger)));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCitiesList(BuildContext context, CategoryCubit cubit) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state.status.isLoading) return const TableShimmer(columns: 1);
        if (state.cities.isEmpty) return Center(child: Text(AppStrings.noCitiesFound, style: const TextStyle(color: AppColors.textSecondary)));
        
        return ListView.separated(
          itemCount: state.cities.length,
          separatorBuilder: (_, __) => Divider(color: AppColors.borderDefault),
          itemBuilder: (context, index) {
            final city = state.cities[index];
            return ListTile(
              title: Text(city.nameEn, style: const TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(city.nameAr, style: const TextStyle(color: AppColors.textSecondary)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: city.isActive, 
                    onChanged: (val) => cubit.updateCity(city.copyWith(isActive: val)),
                    activeColor: AppColors.success,
                  ),
                  IconButton(icon: const Icon(Icons.edit, color: AppColors.textSecondary), onPressed: () => _showCityDialog(context, cubit, city: city)),
                  IconButton(icon: const Icon(Icons.delete, color: AppColors.danger), onPressed: () => _confirmCityDelete(context, cubit, city)),
                ],
              ),
            );
          },
        );
      },
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
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.outlined,
            onPressed: () => Navigator.pop(diagContext),
          ),
          AppButton(
            text: AppStrings.delete,
            variant: AppButtonVariant.danger,
            onPressed: () {
              cubit.deleteCategory(category.id);
              Navigator.pop(diagContext);
            },
          ),
        ],
      ),
    );
  }

  void _confirmCityDelete(BuildContext context, CategoryCubit cubit, CityEntity city) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.deleteCity, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${AppStrings.deleteCityWarning} "${city.nameEn}"?'),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.outlined,
            onPressed: () => Navigator.pop(diagContext),
          ),
          AppButton(
            text: AppStrings.delete,
            variant: AppButtonVariant.danger,
            onPressed: () {
              cubit.deleteCity(city.id);
              Navigator.pop(diagContext);
            },
          ),
        ],
      ),
    );
  }
}
