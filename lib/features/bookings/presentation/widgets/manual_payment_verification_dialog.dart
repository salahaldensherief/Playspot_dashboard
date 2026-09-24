import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_cached_image.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManualPaymentVerificationDialog extends StatefulWidget {
  final Booking booking;

  const ManualPaymentVerificationDialog({super.key, required this.booking});

  @override
  State<ManualPaymentVerificationDialog> createState() => _ManualPaymentVerificationDialogState();
}

class _ManualPaymentVerificationDialogState extends State<ManualPaymentVerificationDialog> {
  String? _signedReceiptUrl;
  bool _isLoadingReceipt = true;
  String? _selectedRejectionReason;
  bool _isRejecting = false;

  final List<String> _rejectionReasons = [
    'إيصال غير واضح / غير مقروء',
    'المبلغ المحول لا يطابق قيمة الحجز',
    'المرجع مستخدم سابقاً / تحويل مكرر',
    'رقم المرسل أو الحساب غير معروف',
    'سبب آخر',
  ];

  @override
  void initState() {
    super.initState();
    _resolveReceiptUrl();
  }

  Future<void> _resolveReceiptUrl() async {
    final path = widget.booking.receiptUrl;
    if (path == null || path.isEmpty) {
      if (mounted) setState(() => _isLoadingReceipt = false);
      return;
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      if (mounted) {
        setState(() {
          _signedReceiptUrl = path;
          _isLoadingReceipt = false;
        });
      }
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final cleanPath = path.replaceAll(RegExp(r'^receipts/'), '');
      final url = await supabase.storage.from('receipts').createSignedUrl(cleanPath, 3600);
      if (mounted) {
        setState(() {
          _signedReceiptUrl = url;
          _isLoadingReceipt = false;
        });
      }
    } catch (_) {
      try {
        final supabase = Supabase.instance.client;
        final cleanPath = path.replaceAll(RegExp(r'^receipts/'), '');
        final pubUrl = supabase.storage.from('receipts').getPublicUrl(cleanPath);
        if (mounted) {
          setState(() {
            _signedReceiptUrl = pubUrl;
            _isLoadingReceipt = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingReceipt = false);
      }
    }
  }

  void _handleApprove(BuildContext context) async {
    final user = context.read<LoginCubit>().state.user;
    final cubit = context.read<BookingCubit>();

    final success = await cubit.approveManualBooking(widget.booking.id, user?.id ?? '');
    if (mounted && context.mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('manual_booking_approved'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _handleReject(BuildContext context) async {
    if (_selectedRejectionReason == null || _selectedRejectionReason!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('select_rejection_reason_required'.tr()),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final user = context.read<LoginCubit>().state.user;
    final cubit = context.read<BookingCubit>();

    final success = await cubit.rejectManualBooking(
      widget.booking.id,
      _selectedRejectionReason!,
      user?.id ?? '',
    );

    if (mounted && context.mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('manual_booking_rejected'.tr()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final formattedDate = DateFormat('yyyy-MM-dd').format(b.date);
    final formattedTime = '${b.startTime} - ${b.endTime}';

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 800.w,
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppColors.neonBlue, size: 28.r),
                    SizedBox(width: 12.w),
                    AppText.heading('manual_payment_verification'.tr(), fontSize: 20.sp),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(color: AppColors.borderDefault, height: 24.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Customer & Payment Metadata
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('customer_info'.tr(), Icons.person_outline),
                      SizedBox(height: 8.h),
                      _buildMetaTile('name'.tr(), b.userName ?? 'N/A'),
                      _buildMetaTile('phone'.tr(), b.userPhone ?? 'N/A', copyable: true),
                      SizedBox(height: 16.h),
                      _buildSectionHeader('booking_details'.tr(), Icons.meeting_room_outlined),
                      SizedBox(height: 8.h),
                      _buildMetaTile('room'.tr(), b.roomName.isNotEmpty ? b.roomName : 'N/A'),
                      _buildMetaTile('date'.tr(), formattedDate),
                      _buildMetaTile('time'.tr(), formattedTime),
                      _buildMetaTile('amount'.tr(), '${b.totalPrice.toStringAsFixed(2)} ${AppStrings.egp}'),
                      SizedBox(height: 16.h),
                      _buildSectionHeader('payment_details'.tr(), Icons.account_balance_wallet_outlined),
                      SizedBox(height: 8.h),
                      _buildMetaTile('sender_wallet_phone'.tr(), b.senderWalletPhone ?? b.userPhone ?? 'N/A', copyable: true),
                      _buildMetaTile('transaction_ref'.tr(), b.id, copyable: true),
                      if (_isRejecting) ...[
                        SizedBox(height: 20.h),
                        CustomDropdown<String>(
                          label: 'select_rejection_reason'.tr(),
                          value: _selectedRejectionReason,
                          items: _rejectionReasons,
                          itemLabel: (item) => item,
                          onChanged: (val) => setState(() => _selectedRejectionReason = val),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 24.w),
                // Right Column: Zoomable Image Viewer
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('proof_receipt'.tr(), Icons.image_search_rounded),
                      SizedBox(height: 12.h),
                      Container(
                        height: 320.h,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: _isLoadingReceipt
                              ? const Center(child: CircularProgressIndicator(color: AppColors.neonBlue))
                              : (_signedReceiptUrl != null && _signedReceiptUrl!.isNotEmpty
                                  ? InteractiveViewer(
                                      panEnabled: true,
                                      minScale: 0.8,
                                      maxScale: 4.0,
                                      child: AppCachedImage(
                                        imageUrl: _signedReceiptUrl!,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 48.r),
                                          SizedBox(height: 8.h),
                                          AppText.body('no_receipt_image'.tr(), color: AppColors.textMuted),
                                        ],
                                      ),
                                    )),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isRejecting) ...[
                  AppButton(
                    text: 'reject_manual_booking'.tr(),
                    variant: AppButtonVariant.danger,
                    onPressed: () => setState(() => _isRejecting = true),
                  ),
                  SizedBox(width: 12.w),
                  AppButton(
                    text: 'approve_manual_booking'.tr(),
                    variant: AppButtonVariant.primary,
                    onPressed: () => _handleApprove(context),
                  ),
                ] else ...[
                  AppButton(
                    text: AppStrings.cancel,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => setState(() => _isRejecting = false),
                  ),
                  SizedBox(width: 12.w),
                  AppButton(
                    text: 'confirm_rejection'.tr(),
                    variant: AppButtonVariant.danger,
                    onPressed: () => _handleReject(context),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.neonBlue, size: 18.r),
        SizedBox(width: 8.w),
        AppText.subHeading(title, fontSize: 14.sp, color: AppColors.neonBlue),
      ],
    );
  }

  Widget _buildMetaTile(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.body(label, color: AppColors.textSecondary, fontSize: 12.sp),
          Row(
            children: [
              AppText.body(value, color: AppColors.textPrimary, fontSize: 12.sp, fontWeight: FontWeight.bold),
              if (copyable && value != 'N/A') ...[
                SizedBox(width: 6.w),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('copied_to_clipboard'.tr()),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Icon(Icons.copy_rounded, color: AppColors.neonBlue, size: 14.r),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
