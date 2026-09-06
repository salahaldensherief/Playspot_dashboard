import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../lounges/domain/entities/extra_entity.dart';
import '../../../lounges/presentation/cubit/extras_cubit.dart';
import '../../../lounges/presentation/cubit/extras_state.dart';

class AddExtrasDialog extends StatefulWidget {
  final String bookingId;
  final String loungeId;
  final Function(List<Map<String, dynamic>> extras, double totalCost) onConfirm;

  const AddExtrasDialog({
    super.key,
    required this.bookingId,
    required this.loungeId,
    required this.onConfirm,
  });

  @override
  State<AddExtrasDialog> createState() => _AddExtrasDialogState();
}

class _AddExtrasDialogState extends State<AddExtrasDialog> {
  final Map<String, int> _selectedQuantities = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExtrasCubit>().loadExtras(widget.loungeId);
    });
  }

  double _calculateTotal(List<ExtraEntity> availableExtras) {
    double total = 0.0;
    for (final extra in availableExtras) {
      final qty = _selectedQuantities[extra.id] ?? 0;
      if (qty > 0) {
        total += extra.price * qty;
      }
    }
    return total;
  }

  List<Map<String, dynamic>> _buildExtrasJsonList(List<ExtraEntity> availableExtras) {
    final List<Map<String, dynamic>> result = [];
    for (final extra in availableExtras) {
      final qty = _selectedQuantities[extra.id] ?? 0;
      if (qty > 0) {
        result.add({
          'id': extra.id,
          'name': extra.name,
          'name_ar': extra.nameAr.isNotEmpty ? extra.nameAr : extra.name,
          'name_en': extra.nameEn.isNotEmpty ? extra.nameEn : extra.name,
          'quantity': qty,
          'qty': qty,
          'price': extra.price,
          'unit_price': extra.price,
          'total_price': extra.price * qty,
        });
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Container(
        width: 500.w,
        constraints: BoxConstraints(maxHeight: 600.h),
        padding: EdgeInsets.all(20.r),
        child: BlocBuilder<ExtrasCubit, ExtrasState>(
          builder: (context, state) {
            if (state.status == ExtrasStatus.loading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.neonBlue),
                ),
              );
            }

            if (state.status == ExtrasStatus.failure) {
              return Center(
                child: AppText.body(
                  state.errorMessage ?? AppStrings.error,
                  color: AppColors.danger,
                ),
              );
            }

            final availableExtras = state.extras.where((e) => !e.isOutOfStock).toList();
            final totalCost = _calculateTotal(availableExtras);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.restaurant_menu, color: AppColors.neonBlue, size: 22.r),
                        SizedBox(width: 8.w),
                        AppText.heading(
                          AppStrings.addExtrasToSession,
                          fontSize: 16.sp,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Extras List
                if (availableExtras.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    child: Center(
                      child: AppText.body(
                        AppStrings.noExtrasAvailable,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: availableExtras.length,
                      separatorBuilder: (_, __) => Divider(color: AppColors.divider, height: 16.h),
                      itemBuilder: (context, index) {
                        final extra = availableExtras[index];
                        final qty = _selectedQuantities[extra.id] ?? 0;

                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 16.r,
                              backgroundColor: AppColors.neonBlue.withValues(alpha: 0.1),
                              child: Icon(Icons.local_cafe, size: 16.r, color: AppColors.neonBlue),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText.subHeading(
                                    extra.nameAr.isNotEmpty ? extra.nameAr : extra.name,
                                    fontSize: 13.sp,
                                  ),
                                  AppText.body(
                                    '${extra.price.toStringAsFixed(0)} ${AppStrings.egp}',
                                    fontSize: 11.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                            // Quantity Controls
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: qty > 0 ? AppColors.danger : AppColors.textMuted,
                                  iconSize: 22.r,
                                  onPressed: qty > 0
                                      ? () {
                                          setState(() {
                                            _selectedQuantities[extra.id] = qty - 1;
                                          });
                                        }
                                      : null,
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                                  child: AppText.subHeading(
                                    '$qty',
                                    fontSize: 14.sp,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: AppColors.neonBlue,
                                  iconSize: 22.r,
                                  onPressed: () {
                                    setState(() {
                                      _selectedQuantities[extra.id] = qty + 1;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                SizedBox(height: 16.h),
                Divider(color: AppColors.divider),
                SizedBox(height: 8.h),

                // Total Summary & Confirm Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.body(
                          AppStrings.extrasTotal,
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                        ),
                        AppText.subHeading(
                          '${totalCost.toStringAsFixed(0)} ${AppStrings.egp}',
                          fontSize: 16.sp,
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        AppButton(
                          text: AppStrings.cancel,
                          variant: AppButtonVariant.text,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        SizedBox(width: 8.w),
                        AppButton(
                          text: AppStrings.confirmAddExtras,
                          variant: AppButtonVariant.primary,
                          height: 38.h,
                          onPressed: totalCost > 0
                              ? () {
                                  final extrasJson = _buildExtrasJsonList(availableExtras);
                                  widget.onConfirm(extrasJson, totalCost);
                                  Navigator.of(context).pop();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
