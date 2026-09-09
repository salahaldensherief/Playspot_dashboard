import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? errorWidget;
  final Widget? placeholder;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.errorWidget,
    this.placeholder,
    this.memCacheWidth = 600,
    this.memCacheHeight = 600,
  });

  /// Helper to return a CachedNetworkImageProvider for CircleAvatar / DecorationImage
  static ImageProvider? provider(String? url, {int? maxCacheWidth = 400, int? maxCacheHeight = 400}) {
    if (url == null || url.trim().isEmpty) return null;
    return CachedNetworkImageProvider(
      url.trim(),
      maxWidth: maxCacheWidth,
      maxHeight: maxCacheHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl?.trim() ?? '';

    if (cleanUrl.isEmpty) {
      return _buildErrorWidget();
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: cleanUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
    );

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius.r),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.mutedBackground,
      child: Center(
        child: SizedBox(
          width: 20.r,
          height: 20.r,
          child: CircularProgressIndicator(
            strokeWidth: 2.r,
            color: AppColors.neonBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: AppColors.mutedBackground,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textSecondary,
        size: 24.r,
      ),
    );
  }
}
