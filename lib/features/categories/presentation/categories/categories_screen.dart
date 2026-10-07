import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_adaptive_page_header.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import '../../domain/entities/activity_type_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/city_entity.dart';
import 'category_cubit.dart';
import 'category_state.dart';
import 'widgets/activity_type_dialog.dart';
import 'widgets/category_card.dart';
import 'widgets/category_dialog.dart';
import 'widgets/city_dialog.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CategoryCubit>().loadCategories();
      }
    });
  }

  void _handleTabChanged() {
    if (mounted && !_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _showCategoryDialog(
    BuildContext context,
    CategoryCubit cubit, {
    CategoryEntity? category,
  }) {
    showDialog(
      context: context,
      builder: (diagContext) => CategoryDialog(
        category: category,
        onSave: (value) {
          if (category == null) {
            cubit.addCategory(value);
          } else {
            cubit.updateCategory(value);
          }
        },
      ),
    );
  }

  void _showActivityDialog(
    BuildContext context,
    CategoryCubit cubit, {
    ActivityTypeEntity? activity,
  }) {
    showDialog(
      context: context,
      builder: (diagContext) => ActivityTypeDialog(
        activity: activity,
        onSave: cubit.saveActivityType,
      ),
    );
  }

  void _showCityDialog(
    BuildContext context,
    CategoryCubit cubit, {
    CityEntity? city,
  }) {
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
    EasyLocalization.of(context);
    final categoryCubit = context.read<CategoryCubit>();

    return DashboardLayout(
      title: AppStrings.categories,
      activeRoute: 'Categories',
      isScrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAdaptivePageHeader(
            title: AppStrings.categories,
            subtitle: AppStrings.manageRoomsDesc,
            primaryAction: AppButton(
              text: _tabController.index == 0
                  ? AppStrings.addCategory
                  : _tabController.index == 1
                  ? AppStrings.addNewActivity
                  : AppStrings.addCity,
              onPressed: () {
                if (_tabController.index == 0) {
                  _showCategoryDialog(context, categoryCubit);
                } else if (_tabController.index == 1) {
                  _showActivityDialog(context, categoryCubit);
                } else {
                  _showCityDialog(context, categoryCubit);
                }
              },
              icon: Icons.add,
            ),
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
              Tab(text: AppStrings.roomActivities),
              Tab(text: AppStrings.cities),
            ],
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryDefinitionsGrid(context, categoryCubit),
                _buildActivityTypesGrid(context, categoryCubit),
                _buildCitiesList(context, categoryCubit),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDefinitionsGrid(
    BuildContext context,
    CategoryCubit categoryCubit,
  ) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state.status.isLoading) {
          return const GridShimmer(itemCount: 6, aspectRatio: 2.5);
        }
        if (state.status.isFailure) {
          return Center(
            child: Text(
              state.errorMessage ?? 'Error',
              style: const TextStyle(color: AppColors.danger),
            ),
          );
        }
        if (state.categories.isEmpty) {
          return Center(
            child: Text(
              AppStrings.noCategoriesFound,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final crossAxisCount = Responsive.isMobile(context)
            ? 1
            : (Responsive.isTablet(context) ? 2 : 3);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16.r,
            mainAxisSpacing: 16.r,
            mainAxisExtent: 100.h,
          ),
          itemCount: state.categories.length,
          itemBuilder: (context, index) {
            final category = state.categories[index];
            return CategoryCard(
              category: category,
              onEdit: () => _showCategoryDialog(
                context,
                categoryCubit,
                category: category,
              ),
              onDelete: () => _confirmCategoryDelete(
                context,
                categoryCubit,
                category,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActivityTypesGrid(
    BuildContext context,
    CategoryCubit categoryCubit,
  ) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state.status.isLoading) {
          return const GridShimmer(itemCount: 6, aspectRatio: 2.5);
        }
        if (state.status.isFailure) {
          return Center(
            child: Text(
              state.errorMessage ?? 'Error',
              style: const TextStyle(color: AppColors.danger),
            ),
          );
        }
        if (state.activityTypes.isEmpty) {
          return Center(
            child: Text(
              AppStrings.noCategoriesFound,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final crossAxisCount = Responsive.isMobile(context)
            ? 1
            : (Responsive.isTablet(context) ? 2 : 3);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16.r,
            mainAxisSpacing: 16.r,
            mainAxisExtent: 120.h,
          ),
          itemCount: state.activityTypes.length,
          itemBuilder: (context, index) {
            final activity = state.activityTypes[index];
            return Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      color: AppColors.neonBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: const Icon(
                      Icons.sports_esports_outlined,
                      color: AppColors.neonBlue,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          activity.label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          activity.name,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${activity.category} • ${activity.pricingModel}',
                          style: const TextStyle(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: AppStrings.edit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => _showActivityDialog(
                      context,
                      categoryCubit,
                      activity: activity,
                    ),
                  ),
                  IconButton(
                    tooltip: AppStrings.delete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                    onPressed: () => _confirmActivityDelete(
                      context,
                      categoryCubit,
                      activity,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCitiesList(BuildContext context, CategoryCubit cubit) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state.status.isLoading) return const TableShimmer(columns: 1);
        if (state.cities.isEmpty)
          return Center(
            child: Text(
              AppStrings.noCitiesFound,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );

        return ListView.separated(
          itemCount: state.cities.length,
          separatorBuilder: (_, _) => Divider(color: AppColors.borderDefault),
          itemBuilder: (context, index) {
            final city = state.cities[index];
            return ListTile(
              title: Text(
                city.nameEn,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                city.nameAr,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: city.isActive,
                    onChanged: (val) =>
                        cubit.updateCity(city.copyWith(isActive: val)),
                    activeThumbColor: AppColors.success,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        _showCityDialog(context, cubit, city: city),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.danger),
                    onPressed: () => _confirmCityDelete(context, cubit, city),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmCategoryDelete(
    BuildContext context,
    CategoryCubit cubit,
    CategoryEntity category,
  ) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          AppStrings.deleteConfirmation,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '${AppStrings.deleteWarning} "${category.nameEn}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
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

  void _confirmActivityDelete(
    BuildContext context,
    CategoryCubit cubit,
    ActivityTypeEntity activity,
  ) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          AppStrings.deleteConfirmation,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '${AppStrings.deleteWarning} "${activity.label}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
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
              cubit.deleteActivityType(activity.id);
              Navigator.pop(diagContext);
            },
          ),
        ],
      ),
    );
  }

  void _confirmCityDelete(
    BuildContext context,
    CategoryCubit cubit,
    CityEntity city,
  ) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          AppStrings.deleteCity,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
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
