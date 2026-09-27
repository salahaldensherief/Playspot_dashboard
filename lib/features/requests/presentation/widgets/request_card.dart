import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/client_request_entity.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/canteen_items_details_box.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/extension_details_row.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/request_card_actions.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/request_customer_tile.dart';

class RequestCard extends StatelessWidget {
  final ClientRequestEntity request;

  const RequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final requestsCubit = context.read<ClientRequestsCubit>();
    final dashboardCubit = context.read<DashboardCubit>();

    final isCallStaff = request.type == ClientRequestType.callStaff;
    final isExtension = request.type == ClientRequestType.extendSession;
    final isCanteen = request.isCanteenOrder;
    final timeFormatted = DateFormat('hh:mm a').format(request.createdAt);

    Color themeColor;
    String typeTagAr;

    if (isCallStaff) {
      themeColor = AppColors.warning;
      typeTagAr = AppStrings.callStaff;
    } else if (isExtension) {
      themeColor = AppColors.neonBlue;
      typeTagAr = AppStrings.clientRequestedExtension;
    } else if (isCanteen) {
      themeColor = AppColors.success;
      typeTagAr = AppStrings.canteenOrder;
    } else {
      themeColor = AppColors.neonPurple;
      typeTagAr = AppStrings.serviceCall;
    }

    String descriptionText = request.bodyAr;
    if (descriptionText.isEmpty || descriptionText == 'طلب من العميل') {
      if (isCallStaff) {
        descriptionText = AppStrings.callStaff;
      } else if (isCanteen) {
        descriptionText = AppStrings.clientRequestedExtras;
      } else if (isExtension) {
        descriptionText = AppStrings.clientRequestedExtension;
      }
    }

    final roomDisplayName = request.roomName ?? AppStrings.roomLabel;
    final userDisplayName =
        (request.userName != null && request.userName!.isNotEmpty)
        ? request.userName!
        : AppStrings.anonymous;

    return Container(
      decoration: BoxDecoration(
        color: request.isAttended
            ? AppColors.cardBackground.withValues(alpha: 0.4)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: request.isAttended
              ? AppColors.borderDefault.withValues(alpha: 0.5)
              : themeColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          if (!request.isAttended)
            BoxShadow(
              color: themeColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: themeColor, width: 4.r),
            ),
          ),
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Bar: Type Tag + Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mutedBackground,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6.r,
                          height: 6.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeColor,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        AppText.body(
                          typeTagAr,
                          color: AppColors.textPrimary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12.r,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: 4.w),
                      AppText.body(
                        timeFormatted,
                        fontSize: 11.sp,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // 2. Room Name Header
              AppText.subHeading(
                roomDisplayName,
                fontSize: 14.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 10.h),

              // 3. Customer Info Tile
              RequestCustomerTile(
                userName: userDisplayName,
                userPhone: request.userPhone,
                userAvatarUrl: request.userAvatarUrl,
              ),
              SizedBox(height: 10.h),

              // 4. Description Body
              AppText.body(
                descriptionText,
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),

              // 5. Details Section (Canteen Items or Extension)
              if (isExtension) ...[
                SizedBox(height: 10.h),
                ExtensionDetailsRow(metadata: request.metadata),
              ] else if (isCanteen && request.canteenItems.isNotEmpty) ...[
                SizedBox(height: 10.h),
                CanteenItemsDetailsBox(
                  items: request.canteenItems,
                  totalPrice: request.totalPrice,
                  note: request.metadata.notes,
                ),
              ],

              // 5b. Embedded Receipt Preview if available
              if (request.bookingId != null && request.bookingId!.isNotEmpty)
                _RequestReceiptPreview(bookingId: request.bookingId!),

              SizedBox(height: 14.h),

              // 6. Action Button Footer
              SizedBox(
                width: double.infinity,
                child: RequestCardActions(
                  request: request,
                  dashboardCubit: dashboardCubit,
                  requestsCubit: requestsCubit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestReceiptPreview extends StatefulWidget {
  final String bookingId;

  const _RequestReceiptPreview({required this.bookingId});

  @override
  State<_RequestReceiptPreview> createState() => _RequestReceiptPreviewState();
}

class _RequestReceiptPreviewState extends State<_RequestReceiptPreview> {
  String? _receiptUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    try {
      final res = await Supabase.instance.client
          .from('bookings')
          .select('receipt_url')
          .eq('id', widget.bookingId)
          .maybeSingle();

      if (res != null && res['receipt_url'] != null) {
        final rawPath = res['receipt_url'].toString().trim();
        if (rawPath.isNotEmpty && rawPath != 'null') {
          if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
            if (mounted)
              setState(() {
                _receiptUrl = rawPath;
                _isLoading = false;
              });
            return;
          }
          final bucketsToTry = [
            'payment-proofs',
            'receipts',
            'booking_receipts',
            'payment_receipts',
            'wallets',
            'payouts',
            'attachments',
          ];
          String cleanPath = rawPath.replaceAll(
            RegExp(
              r'^(payment-proofs|receipts|booking_receipts|payment_receipts|wallets)/',
            ),
            '',
          );

          for (final bucket in bucketsToTry) {
            for (final p in [cleanPath, rawPath]) {
              try {
                final url = await Supabase.instance.client.storage
                    .from(bucket)
                    .createSignedUrl(p, 3600);
                if (url.isNotEmpty && !url.contains('error')) {
                  if (mounted)
                    setState(() {
                      _receiptUrl = url;
                      _isLoading = false;
                    });
                  return;
                }
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 40.h,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.neonBlue,
          ),
        ),
      );
    }

    if (_receiptUrl == null || _receiptUrl!.isEmpty)
      return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        AppText.body(
          'إيصال تحويل الدفع المرفق:',
          fontSize: 11.sp,
          color: AppColors.neonBlue,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.heading(
                            'إيصال تحويل الدفع',
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          _receiptUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: Container(
            height: 90.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: AppColors.neonBlue.withValues(alpha: 0.4),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      _receiptUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.red),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.zoom_in_rounded,
                            color: AppColors.neonBlue,
                            size: 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          AppText.body(
                            'تكبير الإيصال',
                            fontSize: 10.sp,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
