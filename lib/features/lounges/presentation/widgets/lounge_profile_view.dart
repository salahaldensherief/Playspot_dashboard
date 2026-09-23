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
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import '../../domain/entities/lounge.dart';
import '../cubit/lounge_cubit.dart';
import 'core_info_section.dart';
import 'location_info_section.dart';
import 'lounge_payment_methods_section.dart';
import 'quick_discount_section.dart';
import 'working_hours_section.dart';

class LoungeProfileView extends StatefulWidget {
  const LoungeProfileView({super.key});

  @override
  State<LoungeProfileView> createState() => _LoungeProfileViewState();
}

class _LoungeProfileViewState extends State<LoungeProfileView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descArController;
  late TextEditingController _descEnController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _opensAtController;
  late TextEditingController _closesAtController;
  late TextEditingController _vodafoneCashController;
  late TextEditingController _instapayController;

  Uint8List? _mainImageBytes;
  String? _mainImageName;
  List<SelectedImage> _galleryImages = [];
  double? _lat;
  double? _lng;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<LoginCubit>().state.user;
    final lounge = context.read<LoginCubit>().state.userLounge;

    _nameController = TextEditingController(text: lounge?.name ?? '');
    _descArController = TextEditingController(text: lounge?.descriptionAr ?? '');
    _descEnController = TextEditingController(text: lounge?.descriptionEn ?? '');
    _cityController = TextEditingController(text: lounge?.city ?? '');
    _addressController = TextEditingController(text: lounge?.location ?? '');
    _opensAtController = TextEditingController(text: lounge?.opensAt ?? '');
    _closesAtController = TextEditingController(text: lounge?.closesAt ?? '');
    _vodafoneCashController = TextEditingController(text: lounge?.vodafoneCashNumber ?? '');
    _instapayController = TextEditingController(text: lounge?.instapayAccount ?? '');

    _lat = lounge?.lat;
    _lng = lounge?.lng;

    final loungeId = user?.loungeId;
    if (loungeId != null && loungeId.isNotEmpty) {
      context.read<LoginCubit>().refreshUserLounge(loungeId, forceRefresh: true);
    }
  }

  void _populateFromLounge(Lounge lounge) {
    _nameController.text = lounge.name;
    _descArController.text = lounge.descriptionAr ?? '';
    _descEnController.text = lounge.descriptionEn ?? '';
    _cityController.text = lounge.city ?? '';
    _addressController.text = lounge.location ?? '';
    _opensAtController.text = lounge.opensAt;
    _closesAtController.text = lounge.closesAt;
    _vodafoneCashController.text = lounge.vodafoneCashNumber ?? '';
    _instapayController.text = lounge.instapayAccount ?? '';

    _lat = lounge.lat;
    _lng = lounge.lng;
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
    _vodafoneCashController.dispose();
    _instapayController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_vodafoneCashController.text.trim().isEmpty && _instapayController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.paymentMethodsRequiredError),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final lounge = context.read<LoginCubit>().state.userLounge;
        if (lounge == null) return;

        String mainImageUrl = lounge.imageUrl;
        if (_mainImageBytes != null) {
          mainImageUrl = await sl<StorageService>().uploadLoungeImage(
            _mainImageBytes!,
            _mainImageName!,
            lounge.id,
          );
        }

        List<String> galleryUrls = lounge.images ?? [];
        if (_galleryImages.isNotEmpty) {
          final newUrls = await sl<StorageService>().uploadLoungeImages(
            _galleryImages.map((e) => e.bytes).toList(),
            _galleryImages.map((e) => e.name).toList(),
            lounge.id,
          );
          galleryUrls = [...galleryUrls, ...newUrls];
        }

        if (mounted) {
          final updatedLounge = lounge.copyWith(
            name: _nameController.text.trim(),
            descriptionAr: _descArController.text.trim(),
            descriptionEn: _descEnController.text.trim(),
            city: _cityController.text.trim(),
            location: _addressController.text.trim(),
            opensAt: _opensAtController.text.trim(),
            closesAt: _closesAtController.text.trim(),
            imageUrl: mainImageUrl,
            images: galleryUrls,
            lat: _lat,
            lng: _lng,
            vodafoneCashNumber: _vodafoneCashController.text.trim().isEmpty
                ? null
                : _vodafoneCashController.text.trim(),
            instapayAccount: _instapayController.text.trim().isEmpty
                ? null
                : _instapayController.text.trim(),
          );

          await context.read<LoungeCubit>().updateLounge(updatedLounge);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.profileUpdatedSuccess),
                backgroundColor: AppColors.success,
              ),
            );
            await context.read<LoginCubit>().refreshUserLounge(lounge.id, forceRefresh: true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.operationError(e.toString())), backgroundColor: AppColors.danger),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      buildWhen: (prev, curr) => prev.userLounge != curr.userLounge,
      listenWhen: (prev, curr) => prev.userLounge != curr.userLounge,
      listener: (context, state) {
        final lounge = state.userLounge;
        if (lounge != null) {
          _populateFromLounge(lounge);
        }
      },
      builder: (context, loginState) {
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
                    lat: _lat,
                    lng: _lng,
                    onLocationChanged: (lat, lng) => setState(() {
                      _lat = lat;
                      _lng = lng;
                    }),
                  ),
                  SizedBox(height: 32.h),
                  WorkingHoursSection(
                    opensAtController: _opensAtController,
                    closesAtController: _closesAtController,
                    onOpensAtTap: () => _selectTime(context, _opensAtController),
                    onClosesAtTap: () => _selectTime(context, _closesAtController),
                  ),
                  SizedBox(height: 32.h),
                  LoungePaymentMethodsSection(
                    vodafoneCashController: _vodafoneCashController,
                    instapayController: _instapayController,
                  ),
                  SizedBox(height: 40.h),
                  AppButton(
                    text: AppStrings.saveChanges,
                    isLoading: _isSaving,
                    onPressed: _saveProfile,
                    width: 200.w,
                  ),
                  SizedBox(height: 56.h),
                  QuickDiscountSection(
                    lounge: loginState.userLounge,
                    vodafoneCashController: _vodafoneCashController,
                    instapayController: _instapayController,
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (pickerContext, child) {
        return Theme(
          data: Theme.of(pickerContext).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null && context.mounted) {
      final formatted = picked.format(context);
      controller.text = formatted;
    }
  }
}
