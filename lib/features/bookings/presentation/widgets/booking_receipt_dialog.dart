import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_cached_image.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../../../art_core/widgets/app_text_field.dart';
import '../../domain/entities/booking.dart';

class BookingReceiptDialog extends StatefulWidget {
  final Booking booking;
  final VoidCallback onApprove;
  final Function(String reason) onReject;

  const BookingReceiptDialog({
    super.key,
    required this.booking,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<BookingReceiptDialog> createState() => _BookingReceiptDialogState();
}

class _BookingReceiptDialogState extends State<BookingReceiptDialog> {
  final _reasonController = TextEditingController();
  bool _showRejectInput = false;
  String? _signedReceiptUrl;
  bool _isLoadingUrl = true;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  Future<void> _loadSignedUrl() async {
    String? path = widget.booking.receiptUrl;
    if (path == null || path.trim().isEmpty || path == 'null') {
      try {
        final res = await Supabase.instance.client
            .from('bookings')
            .select('receipt_url, receipt_path, payment_receipt, proof_url')
            .eq('id', widget.booking.id)
            .maybeSingle();
        if (res != null) {
          path = (res['receipt_url'] ??
                  res['receipt_path'] ??
                  res['payment_receipt'] ??
                  res['proof_url'])
              ?.toString()
              .trim();
        }
      } catch (_) {}
    }

    if (path == null || path.isEmpty || path == 'null') {
      if (mounted) setState(() => _isLoadingUrl = false);
      return;
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      if (mounted) {
        setState(() {
          _signedReceiptUrl = path;
          _isLoadingUrl = false;
        });
      }
      return;
    }

    final bucketsToTry = ['receipts', 'booking_receipts', 'payment_receipts', 'wallets', 'payouts', 'attachments'];
    String cleanPath = path.replaceAll(RegExp(r'^(receipts|booking_receipts|payment_receipts|wallets)/'), '');

    for (final bucket in bucketsToTry) {
      for (final p in [cleanPath, path]) {
        try {
          final url = await Supabase.instance.client.storage
              .from(bucket)
              .createSignedUrl(p, 3600);
          if (url.isNotEmpty && !url.contains('error')) {
            if (mounted) {
              setState(() {
                _signedReceiptUrl = url;
                _isLoadingUrl = false;
              });
            }
            return;
          }
        } catch (_) {}

        try {
          final pubUrl = Supabase.instance.client.storage
              .from(bucket)
              .getPublicUrl(p);
          if (pubUrl.isNotEmpty) {
            if (mounted) {
              setState(() {
                _signedReceiptUrl = pubUrl;
                _isLoadingUrl = false;
              });
            }
            return;
          }
        } catch (_) {}
      }
    }

    if (mounted) setState(() => _isLoadingUrl = false);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleConfirmReject() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.reasonRequired),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    widget.onReject(reason);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;

    return AppDialog(
      title: '${AppStrings.reviewReceipt} - ${b.userName ?? 'Client'}',
      width: 550.w,
      actions: [
        AppButton(
          text: AppStrings.close,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        if (!_showRejectInput) ...[
          SizedBox(width: 12.w),
          AppButton(
            text: AppStrings.rejectPayment,
            variant: AppButtonVariant.danger,
            onPressed: () => setState(() => _showRejectInput = true),
          ),
          SizedBox(width: 12.w),
          AppButton(
            text: AppStrings.approvePayment,
            backgroundColor: AppColors.success,
            onPressed: () {
              widget.onApprove();
              Navigator.pop(context);
            },
          ),
        ] else ...[
          SizedBox(width: 12.w),
          AppButton(
            text: AppStrings.rejectPayment,
            variant: AppButtonVariant.danger,
            onPressed: _handleConfirmReject,
          ),
        ],
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${AppStrings.customerName}: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
              Text(b.userName ?? 'Client', style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (b.userPhone != null) Text(b.userPhone!, style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
            ],
          ),
          if (b.paymentMethod != null && b.paymentMethod!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(AppStrings.paymentMethodLabel(b.paymentMethod!), style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
          ],
          SizedBox(height: 16.h),
          Text(AppStrings.reviewReceipt, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp)),
          SizedBox(height: 8.h),
          Container(
            height: 320.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.mutedBackground,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            clipBehavior: Clip.antiAlias,
            child: _isLoadingUrl
                ? const Center(child: CircularProgressIndicator())
                : (_signedReceiptUrl != null && _signedReceiptUrl!.isNotEmpty)
                    ? AppCachedImage(
                        imageUrl: _signedReceiptUrl!,
                        fit: BoxFit.contain,
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 48.r, color: AppColors.textSecondary),
                            SizedBox(height: 8.h),
                            Text(
                              'لم يتم إرفاق إيصال دفع من العميل بعد',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                            ),
                            if (b.paymentMethod != null && b.paymentMethod!.isNotEmpty) ...[
                              SizedBox(height: 4.h),
                              Text(
                                'طريقة الدفع: ${b.paymentMethod}',
                                style: TextStyle(color: AppColors.neonBlue, fontSize: 12.sp),
                              ),
                            ],
                          ],
                        ),
                      ),
          ),
          if (_showRejectInput) ...[
            SizedBox(height: 20.h),
            AppTextField(
              controller: _reasonController,
              label: AppStrings.reasonOrNote,
              hintText: AppStrings.reasonHint,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }
}
