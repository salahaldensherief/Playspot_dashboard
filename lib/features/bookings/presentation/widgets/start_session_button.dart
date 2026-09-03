import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../cubit/booking_cubit.dart';

/// Clean UI Button Widget for starting a booking session via Supabase RPC.
class StartSessionButton extends StatefulWidget {
  final String bookingId;
  final VoidCallback? onSuccess;
  final Function(String error)? onError;
  final double? width;
  final double? height;
  final AppButtonVariant variant;

  const StartSessionButton({
    super.key,
    required this.bookingId,
    this.onSuccess,
    this.onError,
    this.width,
    this.height,
    this.variant = AppButtonVariant.primary,
  });

  @override
  State<StartSessionButton> createState() => _StartSessionButtonState();
}

class _StartSessionButtonState extends State<StartSessionButton> {
  bool _isLoading = false;

  Future<void> _handleStartSession(BuildContext context) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cubit = context.read<BookingCubit>();
      final success = await cubit.startBookingSession(widget.bookingId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.sessionStartedSuccess),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
      } else {
        final errorMsg = cubit.state.errorMessage ?? AppStrings.sessionStartFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
        if (widget.onError != null) {
          widget.onError!(errorMsg);
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().isEmpty ? AppStrings.sessionStartFailed : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 3),
        ),
      );
      if (widget.onError != null) {
        widget.onError!(errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: AppStrings.startSession,
      icon: Icons.play_arrow_rounded,
      isLoading: _isLoading,
      width: widget.width,
      height: widget.height ?? 32.h,
      variant: widget.variant,
      onPressed: _isLoading ? null : () => _handleStartSession(context),
    );
  }
}
