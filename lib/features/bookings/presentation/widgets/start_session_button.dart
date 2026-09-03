import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../cubit/booking_cubit.dart';

/// Clean UI Button Widget for starting a booking session via Supabase RPC with start time validation.
class StartSessionButton extends StatefulWidget {
  final String bookingId;
  final DateTime? bookingDate;
  final String? startTime;
  final VoidCallback? onSuccess;
  final Function(String error)? onError;
  final double? width;
  final double? height;

  const StartSessionButton({
    super.key,
    required this.bookingId,
    this.bookingDate,
    this.startTime,
    this.onSuccess,
    this.onError,
    this.width,
    this.height,
  });

  @override
  State<StartSessionButton> createState() => _StartSessionButtonState();
}

class _StartSessionButtonState extends State<StartSessionButton> {
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant StartSessionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookingDate != widget.bookingDate || oldWidget.startTime != widget.startTime) {
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (!_isStartTimeReached) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          setState(() {});
          if (_isStartTimeReached) {
            _timer?.cancel();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime? get _bookingStartTime {
    if (widget.bookingDate == null || widget.startTime == null || widget.startTime!.trim().isEmpty) {
      return null;
    }
    try {
      final date = widget.bookingDate!;
      final parts = widget.startTime!.trim().split(':');
      if (parts.length < 2) return null;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  bool get _isStartTimeReached {
    final start = _bookingStartTime;
    if (start == null) return true; // Default to enabled if no date/time provided
    final now = DateTime.now();
    return now.isAfter(start) || now.isAtSameMomentAs(start);
  }

  String _format12Hour(DateTime dt) {
    return DateFormat('hh:mm a').format(dt);
  }

  Future<void> _handleStartSession(BuildContext context) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final cubit = context.read<BookingCubit>();
      final success = await cubit.startBookingSession(widget.bookingId);

      if (!mounted) return;

      if (success) {
        messenger.showSnackBar(
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
        messenger.showSnackBar(
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
      messenger.showSnackBar(
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
    final bool isReadyToStart = _isStartTimeReached;
    final startDt = _bookingStartTime;

    final String buttonText = isReadyToStart
        ? AppStrings.startSession
        : (startDt != null
            ? AppStrings.startsAt.replaceFirst('{}', _format12Hour(startDt))
            : AppStrings.startSession);

    return AppButton(
      text: buttonText,
      icon: isReadyToStart ? Icons.play_arrow_rounded : Icons.access_time_rounded,
      isLoading: _isLoading,
      width: widget.width,
      height: widget.height ?? 32.h,
      backgroundColor: isReadyToStart ? AppColors.success : AppColors.cardBackground,
      foregroundColor: isReadyToStart ? Colors.white : AppColors.textMuted,
      disabledBackgroundColor: AppColors.cardBackground,
      disabledForegroundColor: AppColors.textMuted,
      onPressed: (!isReadyToStart || _isLoading)
          ? null
          : () => _handleStartSession(context),
    );
  }
}
