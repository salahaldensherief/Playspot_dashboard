import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_multi_image_picker.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../../domain/entities/lounge.dart';
import '../cubit/lounge_cubit.dart';
import '../widgets/lounge_profile_sections.dart';

class LoungeProfilePage extends StatefulWidget {
  const LoungeProfilePage({super.key});

  @override
  State<LoungeProfilePage> createState() => _LoungeProfilePageState();
}

class _LoungeProfilePageState extends State<LoungeProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _descArController;
  late TextEditingController _descEnController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _opensAtController;
  late TextEditingController _closesAtController;

  Uint8List? _mainImageBytes;
  String? _mainImageName;
  List<SelectedImage> _galleryImages = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final lounge = context.read<LoginCubit>().state.userLounge;
    _nameController = TextEditingController(text: lounge?.name);
    _descArController = TextEditingController(text: lounge?.descriptionAr);
    _descEnController = TextEditingController(text: lounge?.descriptionEn);
    _cityController = TextEditingController(text: lounge?.city);
    _addressController = TextEditingController(text: lounge?.location);
    _opensAtController = TextEditingController(text: lounge?.opensAt);
    _closesAtController = TextEditingController(text: lounge?.closesAt);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descArController.dispose();
    _descEnController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _opensAtController.dispose();
    _closesAtController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_galleryImages.isEmpty && context.read<LoginCubit>().state.userLounge?.images == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.minImagesError), backgroundColor: AppColors.danger),
        );
        return;
      }

      setState(() => _isSaving = true);
      try {
        final lounge = context.read<LoginCubit>().state.userLounge;
        if (lounge == null) return;

        String mainImageUrl = lounge.imageUrl;
        if (_mainImageBytes != null) {
          mainImageUrl = await sl<StorageService>().uploadLoungeImage(_mainImageBytes!, _mainImageName!);
        }

        List<String> galleryUrls = lounge.images ?? [];
        if (_galleryImages.isNotEmpty) {
          final newUrls = await sl<StorageService>().uploadLoungeImages(
            _galleryImages.map((e) => e.bytes).toList(),
            _galleryImages.map((e) => e.name).toList(),
          );
          galleryUrls = [...galleryUrls, ...newUrls];
        }

        if (mounted) {
          final updatedLounge = lounge.copyWith(
            name: _nameController.text,
            descriptionAr: _descArController.text,
            descriptionEn: _descEnController.text,
            city: _cityController.text,
            location: _addressController.text,
            opensAt: _opensAtController.text,
            closesAt: _closesAtController.text,
            imageUrl: mainImageUrl,
            images: galleryUrls,
          );

          await context.read<LoungeCubit>().repository.updateLounge(updatedLounge);
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
             );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.loungeProfile,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              SizedBox(height: 32.h),
              CoreInfoSection(
                nameController: _nameController,
                descArController: _descArController,
                descEnController: _descEnController,
                onMainImageSelected: (bytes, name) {
                  _mainImageBytes = bytes;
                  _mainImageName = name;
                },
                onGallerySelected: (images) {
                  _galleryImages = images;
                },
              ),
              SizedBox(height: 32.h),
              LocationInfoSection(
                cityController: _cityController,
                addressController: _addressController,
              ),
              SizedBox(height: 32.h),
              WorkingHoursSection(
                opensAtController: _opensAtController,
                closesAtController: _closesAtController,
                onOpensAtTap: () => _selectTime(context, _opensAtController),
                onClosesAtTap: () => _selectTime(context, _closesAtController),
              ),
              SizedBox(height: 40.h),
              AppButton(
                text: AppStrings.saveChanges,
                isLoading: _isSaving,
                onPressed: _saveProfile,
                width: 200.w,
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (mounted) {
        controller.text = picked.format(context);
      }
    }
  }
}

extension on Lounge {
  Lounge copyWith({
    String? name,
    String? descriptionAr,
    String? descriptionEn,
    String? city,
    String? location,
    String? opensAt,
    String? closesAt,
    String? imageUrl,
    List<String>? images,
  }) {
    return Lounge(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating,
      distance: distance,
      pricePerHour: pricePerHour,
      isOpen: isOpen,
      location: location ?? this.location,
      city: city ?? this.city,
      totalReviews: totalReviews,
      availableRooms: availableRooms,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      images: images ?? this.images,
      opensAt: opensAt ?? this.opensAt,
      closesAt: closesAt ?? this.closesAt,
      lat: lat,
      lng: lng,
      categoryIcons: categoryIcons,
      categoryId: categoryId,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      status: status,
    );
  }
}
