import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_cached_image.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../domain/entities/booking.dart';

class BookingReceiptCard extends StatefulWidget {
  final Booking booking;

  const BookingReceiptCard({
    super.key,
    required this.booking,
  });

  @override
  State<BookingReceiptCard> createState() => _BookingReceiptCardState();
}

class _BookingReceiptCardState extends State<BookingReceiptCard> {
  String? _signedReceiptUrl;
  bool _isLoadingUrl = true;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  Future<void> _loadSignedUrl() async {
    final rawPath = widget.booking.receiptUrl;
    debugPrint('🔵 [RECEIPT_CARD] Booking ID: ${widget.booking.id}, raw receiptUrl: $rawPath');

    if (rawPath == null || rawPath.trim().isEmpty || rawPath == 'null') {
      if (mounted) setState(() => _isLoadingUrl = false);
      return;
    }

    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      if (mounted) {
        setState(() {
          _signedReceiptUrl = rawPath;
          _isLoadingUrl = false;
        });
      }
      return;
    }

    String path = rawPath.trim();
    if (path.startsWith('receipts/')) {
      path = path.substring(9);
    } else if (path.startsWith('/receipts/')) {
      path = path.substring(10);
    }

    try {
      final url = await Supabase.instance.client.storage
          .from('receipts')
          .createSignedUrl(path, 3600);
      debugPrint('🟢 [RECEIPT_CARD] Generated signed URL successfully: $url');
      if (mounted) {
        setState(() {
          _signedReceiptUrl = url;
          _isLoadingUrl = false;
        });
      }
    } catch (e1) {
      debugPrint('⚠️ [RECEIPT_CARD] createSignedUrl failed ($e1), trying getPublicUrl...');
      try {
        final pubUrl = Supabase.instance.client.storage
            .from('receipts')
            .getPublicUrl(path);
        debugPrint('🟢 [RECEIPT_CARD] Fallback public URL: $pubUrl');
        if (mounted) {
          setState(() {
            _signedReceiptUrl = pubUrl;
            _isLoadingUrl = false;
          });
        }
      } catch (e2) {
        debugPrint('❌ [RECEIPT_CARD] All receipt URL resolution methods failed: $e2');
        if (mounted) setState(() => _isLoadingUrl = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: AppColors.neonBlue),
              SizedBox(width: 8.w),
              AppText.subHeading(AppStrings.reviewReceipt, fontSize: 16.sp, color: AppColors.textPrimary),
              const Spacer(),
              if (b.paymentMethod != null && b.paymentMethod!.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.neonBlue.withAlpha(30),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: AppText.body(
                    b.paymentMethod!,
                    fontSize: 11.sp,
                    color: AppColors.neonBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            height: 220.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.mutedBackground,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            clipBehavior: Clip.antiAlias,
            child: _isLoadingUrl
                ? const Center(child: CircularProgressIndicator())
                : (_signedReceiptUrl != null && _signedReceiptUrl!.isNotEmpty)
                    ? GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              backgroundColor: Colors.black,
                              child: Stack(
                                children: [
                                  Center(
                                    child: InteractiveViewer(
                                      child: AppCachedImage(
                                        imageUrl: _signedReceiptUrl!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 16.h,
                                    right: 16.w,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AppCachedImage(
                              imageUrl: _signedReceiptUrl!,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 8.h,
                              right: 8.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(180),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                    SizedBox(width: 4.w),
                                    Text('تكبير', style: TextStyle(color: Colors.white, fontSize: 11.sp)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 40.r, color: AppColors.textSecondary),
                            SizedBox(height: 8.h),
                            AppText.body(
                              'لم يتم إرفاق إيصال دفع من العميل بعد',
                              fontSize: 13.sp,
                              color: AppColors.textSecondary,
                            ),
                            if (b.paymentMethod != null && b.paymentMethod!.isNotEmpty) ...[
                              SizedBox(height: 4.h),
                              AppText.body(
                                'طريقة الدفع: ${b.paymentMethod}',
                                fontSize: 11.sp,
                                color: AppColors.neonBlue,
                              ),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
