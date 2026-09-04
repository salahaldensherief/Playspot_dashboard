import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StarRatingBar extends StatelessWidget {
  final double rating;
  final double size;
  final Color filledColor;
  final Color unfilledColor;
  final int maxRating;

  const StarRatingBar({
    super.key,
    required this.rating,
    this.size = 18.0,
    this.filledColor = const Color(0xFFFFB800),
    this.unfilledColor = const Color(0xFF3F3F46),
    this.maxRating = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starValue = index + 1;
        IconData iconData;
        Color iconColor;

        if (rating >= starValue) {
          iconData = Icons.star_rounded;
          iconColor = filledColor;
        } else if (rating >= starValue - 0.5) {
          iconData = Icons.star_half_rounded;
          iconColor = filledColor;
        } else {
          iconData = Icons.star_outline_rounded;
          iconColor = unfilledColor;
        }

        return Padding(
          padding: EdgeInsets.only(right: 2.w),
          child: Icon(
            iconData,
            size: size.r,
            color: iconColor,
          ),
        );
      }),
    );
  }
}
