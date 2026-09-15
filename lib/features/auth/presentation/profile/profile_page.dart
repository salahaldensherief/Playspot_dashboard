import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import '../../../../art_core/widgets/app_cached_image.dart';
import '../../../../core/di/di.dart';
import '../../../categories/domain/entities/city_entity.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../login/login_cubit.dart';
import '../login/login_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<CityEntity> _cities = [];
  bool _loadingCities = false;

  @override
  void initState() {
    super.initState();
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    setState(() => _loadingCities = true);
    try {
      final repo = sl<CategoryRepository>();
      final result = await repo.getCities();
      result.fold(
        (failure) => debugPrint('⚠️ [PROFILE_PAGE] Failed to load cities: ${failure.message}'),
        (citiesList) {
          if (mounted) {
            setState(() => _cities = citiesList);
          }
        },
      );
    } catch (e) {
      debugPrint('⚠️ [PROFILE_PAGE] Error loading cities: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingCities = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, loginState) {
        final user = loginState.user;

        return DashboardLayout(
          title: AppStrings.myProfile,
          activeRoute: AppStrings.myProfile,
          child: Center(
            child: Container(
              width: 600.w,
              padding: EdgeInsets.all(32.r),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAvatar(context, user?.avatarUrl, user?.name ?? ''),
                  SizedBox(height: 32.h),
                  AppTextField(
                    label: AppStrings.fullNameLabel,
                    controller: TextEditingController(text: user?.name),
                    readOnly: true,
                  ),
                  SizedBox(height: 20.h),
                  AppTextField(
                    label: AppStrings.emailAddressLabel,
                    controller: TextEditingController(text: user?.email),
                    readOnly: true,
                  ),
                  SizedBox(height: 20.h),
                  AppTextField(
                    label: AppStrings.roleLabel,
                    controller: TextEditingController(text: user?.role.toString().split('.').last.toUpperCase()),
                    readOnly: true,
                  ),
                  SizedBox(height: 20.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.userCity,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                      ),
                      SizedBox(height: 8.h),
                      _loadingCities
                          ? SizedBox(
                              height: 48.h,
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.neonBlue),
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              initialValue: _cities.any((c) => c.id == user?.cityId) ? user?.cityId : null,
                              dropdownColor: AppColors.cardBackground,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.mutedBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: const BorderSide(color: AppColors.borderDefault),
                                ),
                              ),
                              hint: Text(AppStrings.selectCity, style: const TextStyle(color: AppColors.textSecondary)),
                              items: _cities.map((city) {
                                return DropdownMenuItem<String>(
                                  value: city.id,
                                  child: Text(city.nameAr.isNotEmpty ? city.nameAr : city.nameEn),
                                );
                              }).toList(),
                              onChanged: (selectedCityId) {
                                if (selectedCityId != null && selectedCityId != user?.cityId) {
                                  context.read<LoginCubit>().updateUserCity(selectedCityId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${AppStrings.userCity}: ${AppStrings.active}'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                            ),
                    ],
                  ),
                  SizedBox(height: 40.h),
                  AppButton(
                    text: AppStrings.changePassword,
                    variant: AppButtonVariant.outlined,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppStrings.underConstruction)),
                      );
                    },
                  ),
                  SizedBox(height: 16.h),
                  AppButton(
                    text: AppStrings.logout,
                    variant: AppButtonVariant.primary,
                    onPressed: () => context.read<LoginCubit>().logout(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context, String? url, String name) {
    final bool hasAvatar = url != null && url.trim().isNotEmpty;
    return Stack(
      children: [
        CircleAvatar(
          radius: 60.r,
          backgroundColor: AppColors.neonPurple.withAlpha(25),
          backgroundImage: hasAvatar ? AppCachedImage.provider(url) : null,
          child: !hasAvatar 
            ? AppText.heading(
                name.isNotEmpty ? name[0].toUpperCase() : '?', 
                fontSize: 40.sp, 
                color: AppColors.neonPurple
              )
            : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: () {
              // Image picking logic would go here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppStrings.underConstruction)),
              );
            },
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: const BoxDecoration(
                color: AppColors.neonBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 20.r),
            ),
          ),
        ),
      ],
    );
  }
}
