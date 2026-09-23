import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddBookingVoucherSection extends StatefulWidget {
  final ValueChanged<({String? code, double discount})> onVoucherChanged;

  const AddBookingVoucherSection({
    super.key,
    required this.onVoucherChanged,
  });

  @override
  State<AddBookingVoucherSection> createState() => _AddBookingVoucherSectionState();
}

class _AddBookingVoucherSectionState extends State<AddBookingVoucherSection> {
  final _controller = TextEditingController();
  bool _isValidating = false;
  String? _appliedCode;
  double _discount = 0.0;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validateVoucher() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final validation = await Supabase.instance.client.rpc(
        'validate_voucher_by_code',
        params: {'p_code': code},
      );

      if (validation is Map) {
        final map = Map<String, dynamic>.from(validation);
        final isValid = map['is_valid'] ?? map['valid'] ?? map['success'] ?? true;
        if (isValid == false) {
          final err = map['error'] ?? map['message'] ?? 'كود القسيمة غير صالح أو منتهي الصلاحية';
          _setError(err.toString());
          return;
        }

        final discount = (map['discount_amount'] ?? map['discount_value'] ?? map['amount'] as num?)?.toDouble() ?? 0.0;
        setState(() {
          _appliedCode = code;
          _discount = discount;
          _errorMessage = null;
        });
        widget.onVoucherChanged((code: code, discount: discount));
      } else {
        setState(() {
          _appliedCode = code;
          _discount = 0.0;
          _errorMessage = null;
        });
        widget.onVoucherChanged((code: code, discount: 0.0));
      }
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      _setError(cleanMsg);
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
      _appliedCode = null;
      _discount = 0.0;
    });
    widget.onVoucherChanged((code: null, discount: 0.0));
  }

  void _clearVoucher() {
    _controller.clear();
    setState(() {
      _appliedCode = null;
      _discount = 0.0;
      _errorMessage = null;
    });
    widget.onVoucherChanged((code: null, discount: 0.0));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body('كود القسيمة / Voucher Code', fontWeight: FontWeight.bold),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'أدخل الكود (مثال: 9326D324)',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: AppColors.borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: AppColors.borderDefault),
                  ),
                  suffixIcon: _appliedCode != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                          onPressed: _clearVoucher,
                        )
                      : null,
                ),
                onChanged: (_) {
                  if (_errorMessage != null || _appliedCode != null) {
                    setState(() {
                      _errorMessage = null;
                      _appliedCode = null;
                      _discount = 0.0;
                    });
                    widget.onVoucherChanged((code: null, discount: 0.0));
                  }
                },
              ),
            ),
            SizedBox(width: 8.w),
            AppButton(
              text: _isValidating ? 'جاري التحقق...' : 'تطبيق',
              variant: AppButtonVariant.primary,
              isLoading: _isValidating,
              onPressed: _isValidating ? null : _validateVoucher,
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: 6.h),
          Text(
            _errorMessage!,
            style: TextStyle(color: AppColors.danger, fontSize: 12.sp),
          ),
        ],
        if (_appliedCode != null) ...[
          SizedBox(height: 6.h),
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 16),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  'تم تطبيق الخصم بنجاح لكود $_appliedCode (${_discount.toStringAsFixed(2)} ${AppStrings.egp})',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
