import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import '../../domain/entities/lounge.dart';
import 'lounge_info_form.dart';

class EditLoungeDialog extends StatefulWidget {
  final Lounge lounge;
  final bool isLoading;
  final Future<void> Function(Lounge lounge)? onSave;

  const EditLoungeDialog({
    super.key,
    required this.lounge,
    this.isLoading = false,
    this.onSave,
  });

  @override
  State<EditLoungeDialog> createState() => _EditLoungeDialogState();
}

class _EditLoungeDialogState extends State<EditLoungeDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _vodafoneCashController;
  late TextEditingController _instapayController;
  
  Uint8List? _loungeImageBytes;
  String? _loungeImageName;
  bool _isOpen = true;

  bool _isLocalUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.lounge.name);
    _cityController = TextEditingController(text: widget.lounge.city);
    _vodafoneCashController = TextEditingController(text: widget.lounge.vodafoneCashNumber ?? '');
    _instapayController = TextEditingController(text: widget.lounge.instapayAccount ?? '');
    _isOpen = widget.lounge.isOpen;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _vodafoneCashController.dispose();
    _instapayController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_vodafoneCashController.text.trim().isEmpty && _instapayController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.paymentMethodsRequiredError), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLocalUploading = true);
      
      try {
        String imageUrl = widget.lounge.imageUrl;
        if (_loungeImageBytes != null && _loungeImageName != null) {
          imageUrl = await sl<StorageService>().uploadLoungeImage(
            _loungeImageBytes!, 
            _loungeImageName!, 
            widget.lounge.id
          );
        }

        if (mounted) {
          final updatedLounge = widget.lounge.copyWith(
            name: _nameController.text,
            imageUrl: imageUrl,
            city: _cityController.text,
            isOpen: _isOpen,
            vodafoneCashNumber: _vodafoneCashController.text.trim().isEmpty ? null : _vodafoneCashController.text.trim(),
            instapayAccount: _instapayController.text.trim().isEmpty ? null : _instapayController.text.trim(),
          );

          if (widget.onSave != null) {
             await widget.onSave!(updatedLounge);
          }
          
          if (mounted) Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppStrings.error}: $e'), backgroundColor: AppColors.danger),
          );
        }
      } finally {
        if (mounted) setState(() => _isLocalUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: AppStrings.loungeProfile,
      width: 600.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 16.w),
        AppButton(
          text: AppStrings.saveChanges,
          isLoading: widget.isLoading || _isLocalUploading,
          onPressed: _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoungeInfoForm(
              nameController: _nameController,
              cityController: _cityController,
              onImageSelected: (bytes, name) {
                _loungeImageBytes = bytes;
                _loungeImageName = name;
              },
            ),
            SizedBox(height: 24.h),
            _buildStatusSection(),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payment_rounded, color: AppColors.neonBlue),
                      SizedBox(width: 8.w),
                      Text(AppStrings.paymentMethodsTitle, style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(AppStrings.paymentMethodsHint, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
                  SizedBox(height: 16.h),
                  AppTextField(
                    controller: _vodafoneCashController,
                    label: AppStrings.vodafoneCashNumberStr,
                    hintText: '01xxxxxxxxx',
                  ),
                  SizedBox(height: 16.h),
                  AppTextField(
                    controller: _instapayController,
                    label: AppStrings.instapayAccountStr,
                    hintText: 'username@instapay',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withAlpha(128),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(
            _isOpen ? Icons.check_circle_outline : Icons.pause_circle_outline,
            color: _isOpen ? AppColors.success : AppColors.warning,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.status,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
                Text(
                  _isOpen ? AppStrings.usersCanBookNow : AppStrings.loungeIsClosed,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          Switch(
            value: _isOpen,
            onChanged: (val) => setState(() => _isOpen = val),
            activeColor: AppColors.neonBlue,
          ),
        ],
      ),
    );
  }
}
