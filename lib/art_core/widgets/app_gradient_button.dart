import 'package:flutter/material.dart';
import 'app_button.dart';

class AppGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const AppGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.gradient,
      isLoading: isLoading,
      width: double.infinity,
    );
  }
}
