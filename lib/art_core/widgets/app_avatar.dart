import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_cached_image.dart';

/// Keeps the identity fallback visible if a remote avatar cannot be decoded.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.radius,
    required this.fallback,
    this.imageUrl,
    this.imageProvider,
    this.backgroundColor = AppColors.cardBackground,
  });
  final double radius;
  final Widget fallback;
  final String? imageUrl;
  final ImageProvider? imageProvider;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final provider = imageProvider ?? AppCachedImage.provider(imageUrl);
    return ClipOval(
      child: SizedBox.square(
        dimension: radius * 2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: backgroundColor,
              child: Center(child: fallback),
            ),
            if (provider != null)
              Image(
                image: provider,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}
