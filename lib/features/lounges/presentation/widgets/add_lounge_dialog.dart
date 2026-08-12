import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/map_location_picker.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/lounge.dart';
import 'lounge_info_form.dart';
import 'owner_info_form.dart';

class AddLoungeDialog extends StatefulWidget {
  final bool isLoading;
  final Function(Lounge lounge, String ownerName, String ownerEmail, String ownerPassword)? onSave;

  const AddLoungeDialog({
    super.key, 
    this.isLoading = false,
    this.onSave,
  });

  @override
  State<AddLoungeDialog> createState() => _AddLoungeDialogState();
}

class _AddLoungeDialogState extends State<AddLoungeDialog> {
  final _formKey = GlobalKey<FormState>();
  final String _loungeId = const Uuid().v4();
  
  // Controllers
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  
  LatLng? _selectedLocation;
  Uint8List? _loungeImageBytes;
  String? _loungeImageName;

  bool _isLocalUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLocalUploading = true);
      
      try {
        String imageUrl = '';
        if (_loungeImageBytes != null && _loungeImageName != null) {
          imageUrl = await sl<StorageService>().uploadLoungeImage(_loungeImageBytes!, _loungeImageName!, _loungeId);
        }

        if (mounted) {
          final lounge = Lounge(
            id: _loungeId,
            name: _nameController.text,
            imageUrl: imageUrl,
            location: 'Address placeholder',
            city: _cityController.text,
            lat: _selectedLocation?.latitude,
            lng: _selectedLocation?.longitude,
            opensAt: '10:00 AM',
            closesAt: '02:00 AM',
            categoryId: null,
          );

          if (widget.onSave != null) {
             await widget.onSave!(
               lounge,
               _ownerNameController.text,
               _ownerEmailController.text,
               _ownerPasswordController.text,
             );
          }
          
          if (mounted) Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
          );
        }
      } finally {
        if (mounted) setState(() => _isLocalUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 1000.w,
        padding: EdgeInsets.all(32.r),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 32.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: LoungeInfoForm(
                        nameController: _nameController,
                        cityController: _cityController,
                        onImageSelected: (bytes, name) {
                          _loungeImageBytes = bytes;
                          _loungeImageName = name;
                        },
                      ),
                    ),
                    SizedBox(width: 32.w),
                    Expanded(
                      flex: 1,
                      child: _buildMapSection(),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),
                const Divider(color: AppColors.divider),
                SizedBox(height: 32.h),
                OwnerInfoForm(
                  nameController: _ownerNameController,
                  emailController: _ownerEmailController,
                  passwordController: _ownerPasswordController,
                ),
                SizedBox(height: 40.h),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.loungeSetup,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.pinLocationMap,
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp),
        ),
        SizedBox(height: 12.h),
        MapLocationPicker(
          onLocationSelected: (location) {
            setState(() => _selectedLocation = location);
          },
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 16.w),
        AppButton(
          text: AppStrings.createLoungeAdmin,
          isLoading: widget.isLoading || _isLocalUploading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
