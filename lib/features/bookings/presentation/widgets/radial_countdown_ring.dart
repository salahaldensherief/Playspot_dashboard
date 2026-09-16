import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';

/// Reusable animated radial progress ring widget for active gaming session timers.
/// Displays dynamic real-time progress & color-coded status feedback.
class RadialCountdownRing extends StatefulWidget {
  final Duration totalDuration;
  final Duration remainingDuration;
  final bool isExpired;
  final bool isOpenEnded;
  final bool showText;
  final double size;
  final double strokeWidth;
  final TextStyle? textStyle;

  const RadialCountdownRing({
    super.key,
    required this.totalDuration,
    required this.remainingDuration,
    this.isExpired = false,
    this.isOpenEnded = false,
    this.showText = true,
    this.size = 54.0,
    this.strokeWidth = 4.0,
    this.textStyle,
  });

  @override
  State<RadialCountdownRing> createState() => _RadialCountdownRingState();
}

class _RadialCountdownRingState extends State<RadialCountdownRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isExpired) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant RadialCountdownRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpired && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isExpired && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    if (widget.isExpired) {
      return AppColors.danger;
    }
    if (widget.isOpenEnded) {
      return AppColors.neonPurple;
    }
    final remainingMinutes = widget.remainingDuration.inMinutes;
    if (remainingMinutes <= 10) {
      return AppColors.warning;
    }
    if (remainingMinutes <= 30) {
      return AppColors.neonBlue;
    }
    return AppColors.success;
  }

  double get _progress {
    if (widget.isOpenEnded || widget.totalDuration.inSeconds <= 0) {
      return 1.0;
    }
    if (widget.isExpired) {
      return 0.0;
    }
    final ratio = widget.remainingDuration.inSeconds / widget.totalDuration.inSeconds;
    return ratio.clamp(0.0, 1.0);
  }

  String get _centerText {
    if (widget.isOpenEnded) {
      return '∞';
    }
    if (widget.isExpired) {
      return '00:00';
    }
    final seconds = widget.remainingDuration.inSeconds.abs();
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    final hrs = seconds ~/ 3600;

    if (hrs > 0) {
      return '${hrs}h';
    }
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = _statusColor;
    final progress = _progress;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = widget.isExpired ? 1.0 + (_pulseController.value * 0.06) : 1.0;
        final opacity = widget.isExpired ? 0.7 + (_pulseController.value * 0.3) : 1.0;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: SizedBox(
              width: widget.size.r,
              height: widget.size.r,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(widget.size.r, widget.size.r),
                    painter: _RingPainter(
                      progress: progress,
                      ringColor: ringColor,
                      trackColor: AppColors.mutedBackground,
                      strokeWidth: widget.strokeWidth.r,
                    ),
                  ),
                  _buildCenterWidget(ringColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterWidget(Color ringColor) {
    if (!widget.showText) {
      if (widget.isOpenEnded) {
        return Icon(Icons.all_inclusive, size: (widget.size * 0.45).r, color: ringColor);
      }
      if (widget.isExpired) {
        return Icon(Icons.warning_amber_rounded, size: (widget.size * 0.45).r, color: ringColor);
      }
      return Icon(Icons.access_time_rounded, size: (widget.size * 0.45).r, color: ringColor);
    }

    return Text(
      _centerText,
      style: widget.textStyle ??
          TextStyle(
            color: ringColor,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'SpaceGrotesk',
          ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..strokeWidth = strokeWidth
      ..color = trackColor
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    final ringPaint = Paint()
      ..strokeWidth = strokeWidth
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top
      sweepAngle,
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
