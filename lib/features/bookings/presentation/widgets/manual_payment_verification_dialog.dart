import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_cached_image.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManualPaymentVerificationDialog extends StatefulWidget {
  final Booking booking;
  final Future<String?> Function(Booking booking)? receiptUrlResolver;

  const ManualPaymentVerificationDialog({
    super.key,
    required this.booking,
    this.receiptUrlResolver,
  });

  @override
  State<ManualPaymentVerificationDialog> createState() =>
      _ManualPaymentVerificationDialogState();
}

class _ManualPaymentVerificationDialogState
    extends State<ManualPaymentVerificationDialog> {
  String? _signedReceiptUrl;
  bool _isLoadingReceipt = true;
  String? _selectedRejectionReason;
  bool _isRejecting = false;
  bool _isSubmitting = false;

  List<String> get _rejectionReasons => [
    AppStrings.rejectionReasonUnclear,
    AppStrings.rejectionReasonAmountMismatch,
    AppStrings.rejectionReasonDuplicate,
    AppStrings.rejectionReasonUnknownSender,
    AppStrings.rejectionReasonOther,
  ];

  @override
  void initState() {
    super.initState();
    _resolveReceiptUrl();
  }

  Future<void> _resolveReceiptUrl() async {
    if (widget.receiptUrlResolver != null) {
      String? url;
      try {
        url = await widget.receiptUrlResolver!(widget.booking);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _signedReceiptUrl = url;
          _isLoadingReceipt = false;
        });
      }
      return;
    }

    String? path = widget.booking.receiptUrl;
    if (path == null || path.trim().isEmpty || path == 'null') {
      try {
        final res = await Supabase.instance.client
            .from('bookings')
            .select('receipt_url')
            .eq('id', widget.booking.id)
            .maybeSingle();
        if (res != null) {
          path = res['receipt_url']?.toString().trim();
        }
      } catch (_) {}
    }

    if (path == null || path.isEmpty || path == 'null') {
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

    final isLegacyReceipt = path.startsWith('receipts/');
    final bucket = isLegacyReceipt ? 'receipts' : 'payment-proofs';
    final cleanPath = path.replaceFirst(
      RegExp(r'^(payment-proofs|receipts)/'),
      '',
    );

    try {
      final url = await Supabase.instance.client.storage
          .from(bucket)
          .createSignedUrl(cleanPath, 600);
      if (mounted) {
        setState(() {
          _signedReceiptUrl = url;
          _isLoadingReceipt = false;
        });
      }
      return;
    } catch (_) {}

    if (mounted) setState(() => _isLoadingReceipt = false);
  }

  Future<void> _handleApprove(BuildContext context) async {
    if (_isSubmitting) return;

    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'approve_manual_booking'.tr(),
      message: AppStrings.confirmApprovePaymentProof,
      confirmText: 'approve_manual_booking'.tr(),
      confirmColor: AppColors.success,
    );

    if (confirmed != true || !mounted || !context.mounted) return;

    setState(() => _isSubmitting = true);
    final user = context.read<LoginCubit>().state.user;
    final cubit = context.read<BookingCubit>();

    final success = await cubit.approveManualBooking(
      widget.booking.id,
      user?.id ?? '',
    );
    if (mounted && context.mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('manual_booking_approved'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.actionFailed),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    if (_isSubmitting) return;
    if (_selectedRejectionReason == null || _selectedRejectionReason!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('select_rejection_reason_required'.tr()),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'reject_manual_booking'.tr(),
      message: AppStrings.confirmRejectPaymentProof,
      confirmText: 'reject_manual_booking'.tr(),
      confirmColor: AppColors.danger,
    );

    if (confirmed != true || !mounted || !context.mounted) return;

    setState(() => _isSubmitting = true);
    final user = context.read<LoginCubit>().state.user;
    final cubit = context.read<BookingCubit>();

    final success = await cubit.rejectManualBooking(
      widget.booking.id,
      _selectedRejectionReason!,
      user?.id ?? '',
    );

    if (mounted && context.mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('manual_booking_rejected'.tr()),
            backgroundColor: AppColors.danger,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.actionFailed),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final b = widget.booking;
    final formattedDate = DateFormat('yyyy-MM-dd').format(b.date);
    final formattedTime = '${b.startTime} - ${b.endTime}';

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      insetPadding: EdgeInsets.all(12.r),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 800.w.clamp(0, 800),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        padding: EdgeInsets.all(24.r),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.neonBlue,
                          size: 28.r,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: AppText.heading(
                            'manual_payment_verification'.tr(),
                            fontSize: 20.sp,
                          ),
                        ),
                      ],
                    ),
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
              Divider(color: AppColors.borderDefault, height: 24.h),
              LayoutBuilder(
                builder: (context, constraints) {
                  final details = _buildPaymentDetails(
                    b,
                    formattedDate,
                    formattedTime,
                  );
                  final receipt = _buildReceiptPreview();
                  if (constraints.maxWidth < 680) {
                    return Column(
                      children: [
                        details,
                        SizedBox(height: 24.h),
                        receipt,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: details),
                      SizedBox(width: 24.w),
                      Expanded(child: receipt),
                    ],
                  );
                },
              ),
              SizedBox(height: 24.h),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12.w,
                runSpacing: 8.h,
                children: [
                  if (!_isRejecting) ...[
                    AppButton(
                      text: 'reject_manual_booking'.tr(),
                      variant: AppButtonVariant.danger,
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() => _isRejecting = true),
                    ),
                    AppButton(
                      text: 'approve_manual_booking'.tr(),
                      variant: AppButtonVariant.primary,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting
                          ? null
                          : () => _handleApprove(context),
                    ),
                  ] else ...[
                    AppButton(
                      text: AppStrings.cancel,
                      variant: AppButtonVariant.outlined,
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() => _isRejecting = false),
                    ),
                    AppButton(
                      text: 'confirm_rejection'.tr(),
                      variant: AppButtonVariant.danger,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting
                          ? null
                          : () => _handleReject(context),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(
    Booking b,
    String formattedDate,
    String formattedTime,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('customer_info'.tr(), Icons.person_outline),
        SizedBox(height: 8.h),
        _buildMetaTile('name'.tr(), b.userName ?? 'N/A'),
        _buildMetaTile('phone'.tr(), b.userPhone ?? 'N/A', copyable: true),
        SizedBox(height: 16.h),
        _buildSectionHeader(
          'booking_details'.tr(),
          Icons.meeting_room_outlined,
        ),
        SizedBox(height: 8.h),
        _buildMetaTile('room'.tr(), b.roomName.isNotEmpty ? b.roomName : 'N/A'),
        _buildMetaTile('date'.tr(), formattedDate),
        _buildMetaTile('time'.tr(), formattedTime),
        _buildMetaTile(
          'amount'.tr(),
          '${b.totalPrice.toStringAsFixed(2)} ${AppStrings.egp}',
        ),
        SizedBox(height: 16.h),
        _buildSectionHeader(
          'payment_details'.tr(),
          Icons.account_balance_wallet_outlined,
        ),
        SizedBox(height: 8.h),
        _buildMetaTile(
          'sender_wallet_phone'.tr(),
          b.senderWalletPhone ?? b.userPhone ?? 'N/A',
          copyable: true,
        ),
        _buildMetaTile('transaction_ref'.tr(), b.id, copyable: true),
        if (_isRejecting) ...[
          SizedBox(height: 20.h),
          CustomDropdown<String>(
            label: 'select_rejection_reason'.tr(),
            value: _selectedRejectionReason,
            items: _rejectionReasons,
            itemLabel: (item) => item,
            onChanged: (val) {
              if (!_isSubmitting) {
                setState(() => _selectedRejectionReason = val);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildReceiptPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('proof_receipt'.tr(), Icons.image_search_rounded),
        SizedBox(height: 12.h),
        Container(
          height: 320.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: _isLoadingReceipt
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.neonBlue),
                  )
                : (_signedReceiptUrl != null && _signedReceiptUrl!.isNotEmpty
                      ? InteractiveViewer(
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
                              Icon(
                                Icons.broken_image_rounded,
                                color: AppColors.textMuted,
                                size: 48.r,
                              ),
                              SizedBox(height: 8.h),
                              AppText.body(
                                'no_receipt_image'.tr(),
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        )),
          ),
        ),
      ],
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
          Expanded(
            child: AppText.body(
              label,
              color: AppColors.textSecondary,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AppText.body(
                    value,
                    color: AppColors.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    child: Icon(
                      Icons.copy_rounded,
                      color: AppColors.neonBlue,
                      size: 14.r,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
