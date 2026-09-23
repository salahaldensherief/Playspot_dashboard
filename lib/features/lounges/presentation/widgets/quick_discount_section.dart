import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../../domain/entities/lounge.dart';
import '../cubit/lounge_cubit.dart';

class QuickDiscountSection extends StatefulWidget {
  final Lounge? lounge;
  final TextEditingController vodafoneCashController;
  final TextEditingController instapayController;

  const QuickDiscountSection({
    super.key,
    required this.lounge,
    required this.vodafoneCashController,
    required this.instapayController,
  });

  @override
  State<QuickDiscountSection> createState() => _QuickDiscountSectionState();
}

class _QuickDiscountSectionState extends State<QuickDiscountSection> {
  late TextEditingController _discountPercentageController;
  late TextEditingController _discountTitleArController;
  late TextEditingController _discountTitleEnController;
  late TextEditingController _discountExpirationController;

  bool _hasDiscount = false;
  DateTime? _discountExpiresAt;
  bool _isSavingDiscount = false;

  @override
  void initState() {
    super.initState();
    _initFromLounge(widget.lounge);
  }

  @override
  void didUpdateWidget(covariant QuickDiscountSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lounge != oldWidget.lounge) {
      _initFromLounge(widget.lounge);
    }
  }

  void _initFromLounge(Lounge? lounge) {
    _hasDiscount = lounge?.hasDiscount ?? false;
    _discountPercentageController = TextEditingController(
      text: lounge?.discountPercentage.toString() ?? '0',
    );
    _discountTitleArController = TextEditingController(
      text: lounge?.discountTitleAr ?? '',
    );
    _discountTitleEnController = TextEditingController(
      text: lounge?.discountTitleEn ?? '',
    );
    _discountExpiresAt = lounge?.discountExpiresAt;
    _discountExpirationController = TextEditingController(
      text: _discountExpiresAt != null
          ? _discountExpiresAt!.toLocal().toString().split(' ')[0]
          : '',
    );
  }

  @override
  void dispose() {
    _discountPercentageController.dispose();
    _discountTitleArController.dispose();
    _discountTitleEnController.dispose();
    _discountExpirationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _discountExpiresAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _discountExpiresAt = picked;
        _discountExpirationController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  Future<void> _saveDiscount() async {
    final lounge = widget.lounge;
    if (lounge == null) return;

    final String vodafoneCash = widget.vodafoneCashController.text.trim();
    final String instapay = widget.instapayController.text.trim();

    if (vodafoneCash.isEmpty &&
        instapay.isEmpty &&
        (lounge.vodafoneCashNumber ?? '').isEmpty &&
        (lounge.instapayAccount ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.paymentMethodsRequiredError),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSavingDiscount = true);
    try {
      await context.read<LoungeCubit>().updateLoungeDiscount(
        loungeId: lounge.id,
        hasDiscount: _hasDiscount,
        discountPercentage:
            _hasDiscount ? (int.tryParse(_discountPercentageController.text) ?? 0) : 0,
        titleAr: _hasDiscount ? _discountTitleArController.text.trim() : '',
        titleEn: _hasDiscount ? _discountTitleEnController.text.trim() : '',
        expiresAt: _hasDiscount ? _discountExpiresAt : null,
        vodafoneCashNumber: vodafoneCash.isNotEmpty ? vodafoneCash : lounge.vodafoneCashNumber,
        instapayAccount: instapay.isNotEmpty ? instapay : lounge.instapayAccount,
      );

      if (mounted) {
        final updatedLoungeInState = lounge.copyWith(
          hasDiscount: _hasDiscount,
          discountPercentage:
              _hasDiscount ? (int.tryParse(_discountPercentageController.text) ?? 0) : 0,
          discountTitleAr: _hasDiscount ? _discountTitleArController.text.trim() : '',
          discountTitleEn: _hasDiscount ? _discountTitleEnController.text.trim() : '',
          discountExpiresAt: _hasDiscount ? _discountExpiresAt : null,
          vodafoneCashNumber: vodafoneCash.isNotEmpty ? vodafoneCash : lounge.vodafoneCashNumber,
          instapayAccount: instapay.isNotEmpty ? instapay : lounge.instapayAccount,
        );
        context.read<LoginCubit>().updateUserLounge(updatedLoungeInState);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.discountUpdatedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        await context.read<LoginCubit>().refreshUserLounge(lounge.id, forceRefresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.operationError(e.toString())), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingDiscount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.directDiscount,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    AppStrings.activateDiscount,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _hasDiscount,
                onChanged: (v) => setState(() {
                  _hasDiscount = v;
                  if (!v) {
                    _discountExpiresAt = null;
                    _discountExpirationController.clear();
                  }
                }),
                activeThumbColor: AppColors.neonBlue,
              ),
            ],
          ),
          if (_hasDiscount) ...[
            SizedBox(height: 24.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildField(
                    label: AppStrings.discountPercentage,
                    controller: _discountPercentageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    hint: AppStrings.hintPercentRange,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildField(
                    label: AppStrings.discountExpiration,
                    controller: _discountExpirationController,
                    readOnly: true,
                    onTap: _selectDate,
                    hint: AppStrings.hintDateFormat,
                    suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: AppStrings.discountTitleAr,
                    controller: _discountTitleArController,
                    hint: AppStrings.promoTitleArHint,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildField(
                    label: AppStrings.discountTitleEn,
                    controller: _discountTitleEnController,
                    hint: AppStrings.promoTitleEnHint,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 24.h),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              text: AppStrings.saveChanges,
              isLoading: _isSavingDiscount,
              onPressed: _saveDiscount,
              width: 150.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
            filled: true,
            fillColor: AppColors.mutedBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }
}
