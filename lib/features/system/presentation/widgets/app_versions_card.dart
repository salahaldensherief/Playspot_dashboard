import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';
import '../../domain/entities/app_status_entity.dart';

class AppVersionsCard extends StatefulWidget {
  final AppStatusEntity appStatus;
  final bool isLoading;
  final ValueChanged<AppStatusEntity> onSave;

  const AppVersionsCard({
    super.key,
    required this.appStatus,
    required this.isLoading,
    required this.onSave,
  });

  @override
  State<AppVersionsCard> createState() => _AppVersionsCardState();
}

class _AppVersionsCardState extends State<AppVersionsCard> {
  late TextEditingController _minAndroidController;
  late TextEditingController _minIosController;
  late TextEditingController _latestAndroidController;
  late TextEditingController _latestIosController;
  late TextEditingController _storeAndroidController;
  late TextEditingController _storeIosController;
  late TextEditingController _msgArController;
  late TextEditingController _msgEnController;

  @override
  void initState() {
    super.initState();
    _minAndroidController = TextEditingController(text: widget.appStatus.minAndroidVersion);
    _minIosController = TextEditingController(text: widget.appStatus.minIosVersion);
    _latestAndroidController = TextEditingController(text: widget.appStatus.latestAndroidVersion);
    _latestIosController = TextEditingController(text: widget.appStatus.latestIosVersion);
    _storeAndroidController = TextEditingController(text: widget.appStatus.storeUrlAndroid);
    _storeIosController = TextEditingController(text: widget.appStatus.storeUrlIos);
    _msgArController = TextEditingController(text: widget.appStatus.updateMessageAr);
    _msgEnController = TextEditingController(text: widget.appStatus.updateMessageEn);
  }

  @override
  void didUpdateWidget(covariant AppVersionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appStatus != widget.appStatus) {
      _minAndroidController.text = widget.appStatus.minAndroidVersion;
      _minIosController.text = widget.appStatus.minIosVersion;
      _latestAndroidController.text = widget.appStatus.latestAndroidVersion;
      _latestIosController.text = widget.appStatus.latestIosVersion;
      _storeAndroidController.text = widget.appStatus.storeUrlAndroid;
      _storeIosController.text = widget.appStatus.storeUrlIos;
      _msgArController.text = widget.appStatus.updateMessageAr;
      _msgEnController.text = widget.appStatus.updateMessageEn;
    }
  }

  @override
  void dispose() {
    _minAndroidController.dispose();
    _minIosController.dispose();
    _latestAndroidController.dispose();
    _latestIosController.dispose();
    _storeAndroidController.dispose();
    _storeIosController.dispose();
    _msgArController.dispose();
    _msgEnController.dispose();
    super.dispose();
  }

  void _submit() {
    final updated = widget.appStatus.copyWith(
      minAndroidVersion: _minAndroidController.text.trim(),
      minIosVersion: _minIosController.text.trim(),
      latestAndroidVersion: _latestAndroidController.text.trim(),
      latestIosVersion: _latestIosController.text.trim(),
      storeUrlAndroid: _storeAndroidController.text.trim(),
      storeUrlIos: _storeIosController.text.trim(),
      updateMessageAr: _msgArController.text.trim(),
      updateMessageEn: _msgEnController.text.trim(),
    );
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: AppStrings.appVersionsAndUpdate,
      children: [
        Text(
          AppStrings.appVersionsDesc,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
        ),
        SizedBox(height: 20.h),

        // Android & iOS minimum versions
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.minAndroidVersion,
                hintText: AppStrings.hintVersionNumber,
                controller: _minAndroidController,
                prefixIcon: Icons.android,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.minIosVersion,
                hintText: AppStrings.hintVersionNumber,
                controller: _minIosController,
                prefixIcon: Icons.apple,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Android & iOS latest versions
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.latestAndroidVersion,
                hintText: AppStrings.hintVersionNumber,
                controller: _latestAndroidController,
                prefixIcon: Icons.system_update_alt,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.latestIosVersion,
                hintText: AppStrings.hintVersionNumber,
                controller: _latestIosController,
                prefixIcon: Icons.system_update_alt,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Store URLs
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.playStoreUrl,
                hintText: AppStrings.hintPlayStoreUrl,
                controller: _storeAndroidController,
                prefixIcon: Icons.link,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.appStoreUrl,
                hintText: AppStrings.hintAppStoreUrl,
                controller: _storeIosController,
                prefixIcon: Icons.link,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Update Messages
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.updateMessageAr,
                hintText: AppStrings.updateMessageArHint,
                controller: _msgArController,
                maxLines: 2,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.updateMessageEn,
                hintText: AppStrings.updateMessageEnHint,
                controller: _msgEnController,
                maxLines: 2,
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),

        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: AppButton(
            text: AppStrings.saveVersionsSettings,
            icon: Icons.save,
            isLoading: widget.isLoading,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
