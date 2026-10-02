import 'package:flutter/material.dart';
import 'app_colors.dart';

class OperationsTokens {
  static const gap = 12.0;
  static const valueFontSize = 16.0;
  static const padding = 16.0;
  static const radius = 12.0;
  static const panelHeight = 680.0;
  static const panelViewportFraction = 0.85;
  static const railWidth = 340.0;
  static const factMinimumWidth = 220.0;
  static const headerMinimumWidth = 520.0;
  static const actionWidth = 200.0;
  static const actionHeight = 48.0;
  static const sectionTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.neonCyan,
  );
  static const title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const label = TextStyle(fontSize: 14, color: AppColors.textSecondary);
  static const value = TextStyle(
    fontSize: valueFontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const panel = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.all(Radius.circular(radius)),
    border: Border.fromBorderSide(BorderSide(color: AppColors.borderDefault)),
  );
}
