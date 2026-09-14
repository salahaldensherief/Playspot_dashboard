import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../../../art_core/widgets/app_image_picker.dart';
import '../../../../art_core/widgets/app_text_field.dart';
import '../../../categories/domain/entities/city_entity.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../../core/di/di.dart';
import '../../domain/entities/tournament_entity.dart';

class TournamentFormDialog extends StatefulWidget {
  final TournamentEntity? tournament;
  final String? defaultLoungeId;
  final String? defaultCityId;
  final List<CityEntity>? initialCities;
  final Future<bool> Function(
    TournamentEntity entity,
    Uint8List? bannerBytes,
    String? bannerName,
  ) onSubmit;

  const TournamentFormDialog({
    super.key,
    this.tournament,
    this.defaultLoungeId,
    this.defaultCityId,
    this.initialCities,
    required this.onSubmit,
  });

  @override
  State<TournamentFormDialog> createState() => _TournamentFormDialogState();
}

class _TournamentFormDialogState extends State<TournamentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleArController;
  late TextEditingController _titleEnController;
  late TextEditingController _gameTitleController;
  late TextEditingController _entryFeeController;
  late TextEditingController _prizePoolController;
  late TextEditingController _minPlayersController;
  late TextEditingController _maxPlayersController;
  late TextEditingController _rulesArController;
  late TextEditingController _rulesEnController;
  late TextEditingController _radiusController;

  Uint8List? _bannerBytes;
  String? _bannerName;
  bool _bannerError = false;
  bool _isUploading = false;

  String _visibilityScope = 'all';
  String? _selectedCityId;
  List<CityEntity> _cities = [];
  bool _loadingCities = false;

  int _treeSize = 16;
  DateTime _registrationOpensAt = DateTime.now();
  DateTime _registrationClosesAt = DateTime.now().add(const Duration(days: 5));
  DateTime _checkInOpensAt = DateTime.now().add(const Duration(days: 5, hours: 2));
  DateTime _checkInClosesAt = DateTime.now().add(const Duration(days: 7, hours: -1));
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    final t = widget.tournament;

    _titleArController = TextEditingController(text: t?.titleAr ?? t?.title ?? '');
    _titleEnController = TextEditingController(text: t?.titleEn ?? t?.title ?? '');
    _gameTitleController = TextEditingController(text: t?.gameTitle ?? 'EA FC 25');
    _entryFeeController = TextEditingController(text: t?.entryFee.toString() ?? '50');
    _prizePoolController = TextEditingController(text: t?.prizePool.toString() ?? '500');
    _minPlayersController = TextEditingController(text: t?.minPlayers.toString() ?? '4');
    _maxPlayersController = TextEditingController(text: t?.maxPlayers.toString() ?? '16');
    _rulesArController = TextEditingController(text: t?.descriptionAr ?? t?.rules ?? '');
    _rulesEnController = TextEditingController(text: t?.descriptionEn ?? t?.rules ?? '');

    _visibilityScope = t?.visibilityScope ?? 'all';
    _radiusController = TextEditingController(
      text: t?.visibilityRadiusKm != null ? t!.visibilityRadiusKm.toString() : '',
    );
    _selectedCityId = t?.cityId ?? widget.defaultCityId;

    if (t != null) {
      _treeSize = t.treeSize;
      _startDate = t.startDate;
      _registrationOpensAt = t.registrationOpensAt ?? DateTime.now();
      _registrationClosesAt = t.registrationClosesAt ?? t.registrationDeadline;
      _checkInOpensAt = t.checkInOpensAt ?? t.registrationDeadline.add(const Duration(hours: 1));
      _checkInClosesAt = t.checkInClosesAt ?? t.startDate.subtract(const Duration(hours: 1));
    }

    if (widget.initialCities != null && widget.initialCities!.isNotEmpty) {
      _cities = widget.initialCities!;
      if (_selectedCityId == null && _cities.isNotEmpty) {
        _selectedCityId = _cities.first.id;
      }
    } else {
      _fetchCities();
    }
  }

  Future<void> _fetchCities() async {
    setState(() => _loadingCities = true);
    try {
      if (sl.isRegistered<CategoryRepository>()) {
        final repo = sl<CategoryRepository>();
        final result = await repo.getCities();
        result.fold(
          (failure) => debugPrint('⚠️ [TOURNAMENT_FORM] Cities load error: ${failure.message}'),
          (list) {
            if (mounted) {
              setState(() {
                _cities = list;
                if (_selectedCityId == null && _cities.isNotEmpty) {
                  _selectedCityId = _cities.first.id;
                }
              });
            }
          },
        );
      }
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENT_FORM] Error fetching cities: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingCities = false);
      }
    }
  }

  @override
  void dispose() {
    _titleArController.dispose();
    _titleEnController.dispose();
    _gameTitleController.dispose();
    _entryFeeController.dispose();
    _prizePoolController.dispose();
    _minPlayersController.dispose();
    _maxPlayersController.dispose();
    _rulesArController.dispose();
    _rulesEnController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _onCancelPressed() async {
    final hasInput = _titleArController.text.isNotEmpty ||
        _titleEnController.text.isNotEmpty ||
        _bannerBytes != null;

    if (hasInput) {
      final confirm = await AppDialog.confirm(
        context: context,
        title: AppStrings.cancel,
        message: 'هل أنت متأكد من إلغاء التغييرات والتراجع؟',
        confirmText: AppStrings.cancel,
        confirmColor: AppColors.danger,
      );
      if (confirm == true && mounted) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _selectDateTime(BuildContext context, DateTime initial, Function(DateTime) onPicked) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              onPrimary: Colors.black,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (pickedDate != null && context.mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.neonBlue,
                onPrimary: Colors.black,
                surface: AppColors.cardBackground,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child ?? const SizedBox(),
          );
        },
      );

      final finalDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? initial.hour,
        pickedTime?.minute ?? initial.minute,
      );
      onPicked(finalDateTime);
    }
  }

  Widget _buildDateTimeField(String label, DateTime value, Function(DateTime) onPicked) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6.h),
        InkWell(
          onTap: _isUploading ? null : () => _selectDateTime(context, value, onPicked),
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.mutedBackground,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(value),
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                ),
                const Icon(Icons.calendar_today_rounded, color: AppColors.neonBlue, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    // Validate Banner image requirement
    if (widget.tournament == null && _bannerBytes == null) {
      setState(() => _bannerError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tournamentBannerRequired),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    } else {
      setState(() => _bannerError = false);
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final minP = int.tryParse(_minPlayersController.text.trim()) ?? 0;
    final maxP = int.tryParse(_maxPlayersController.text.trim()) ?? 0;

    if (minP > maxP) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الحد الأدنى للاعبين يجب أن يكون أقل من أو يساوي الحد الأقصى'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (maxP > _treeSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الحد الأقصى للاعبين ($maxP) يتجاوز حجم الشجرة المختاَر ($_treeSize)'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Schedule Validations
    if (_registrationClosesAt.isBefore(_registrationOpensAt) ||
        _registrationClosesAt.isAtSameMomentAs(_registrationOpensAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.regCloseAfterOpenError),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_checkInOpensAt.isBefore(_registrationClosesAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.checkInAfterRegCloseError),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_checkInClosesAt.isAfter(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.checkInBeforeStartError),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Visibility Scope Validations
    if (_visibilityScope == 'city') {
      if (_selectedCityId == null || _selectedCityId!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.cityRequiredError),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    if (_visibilityScope == 'radius') {
      final radiusVal = double.tryParse(_radiusController.text.trim());
      if (radiusVal == null || radiusVal < 1 || radiusVal > 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('نطاق المسافة يجب أن يكون بين 1 و 500 كم'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    setState(() => _isUploading = true);

    try {
      final tournamentId = widget.tournament?.id ?? const Uuid().v4();
      final double? parsedRadius = _visibilityScope == 'radius'
          ? double.tryParse(_radiusController.text.trim())
          : null;

      final String? resolvedCityId = _visibilityScope == 'city'
          ? _selectedCityId
          : (_selectedCityId ?? widget.defaultCityId);

      final titleArText = _titleArController.text.trim().isNotEmpty
          ? _titleArController.text.trim()
          : _titleEnController.text.trim();
      final titleEnText = _titleEnController.text.trim().isNotEmpty
          ? _titleEnController.text.trim()
          : _titleArController.text.trim();

      final descArText = _rulesArController.text.trim().isNotEmpty
          ? _rulesArController.text.trim()
          : _rulesEnController.text.trim();
      final descEnText = _rulesEnController.text.trim().isNotEmpty
          ? _rulesEnController.text.trim()
          : _rulesArController.text.trim();

      final entity = TournamentEntity(
        id: tournamentId,
        title: titleArText,
        titleAr: titleArText,
        titleEn: titleEnText,
        descriptionAr: descArText,
        descriptionEn: descEnText,
        gameTitle: _gameTitleController.text.trim(),
        bannerUrl: widget.tournament?.bannerUrl,
        treeSize: _treeSize,
        status: widget.tournament?.status ?? TournamentStatus.draft,
        entryFee: double.tryParse(_entryFeeController.text.trim()) ?? 0.0,
        prizePool: double.tryParse(_prizePoolController.text.trim()) ?? 0.0,
        startDate: _startDate,
        endDate: widget.tournament?.endDate ?? _startDate.add(const Duration(days: 1)),
        registrationDeadline: _registrationClosesAt,
        registrationOpensAt: _registrationOpensAt,
        registrationClosesAt: _registrationClosesAt,
        checkInOpensAt: _checkInOpensAt,
        checkInClosesAt: _checkInClosesAt,
        tournamentStartsAt: _startDate,
        minPlayers: minP,
        maxPlayers: maxP,
        rules: descArText,
        registeredCount: widget.tournament?.registeredCount ?? 0,
        loungeId: widget.tournament?.loungeId ?? widget.defaultLoungeId,
        cityId: resolvedCityId,
        visibilityScope: _visibilityScope,
        visibilityRadiusKm: parsedRadius,
      );

      final success = await widget.onSubmit(entity, _bannerBytes, _bannerName);

      if (success && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.error}: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        Row(
          children: [
            Icon(icon, color: AppColors.neonBlue, size: 20),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                color: AppColors.neonBlue,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        const Divider(color: AppColors.borderDefault, height: 1),
        SizedBox(height: 16.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.tournament != null;

    return AppDialog(
      title: isEdit ? AppStrings.editTournament : AppStrings.createTournament,
      width: 750.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: _isUploading ? null : _onCancelPressed,
        ),
        SizedBox(width: 12.w),
        AppButton(
          text: isEdit ? AppStrings.saveChanges : AppStrings.createTournament,
          isLoading: _isUploading,
          onPressed: _handleSubmit,
        ),
      ],
      child: AbsorbPointer(
        absorbing: _isUploading,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Basic Info & Banner Section
              _buildSectionHeader('المعلومات الأساسية وإعلان البطولة', Icons.info_outline_rounded),
              Container(
                decoration: _bannerError
                    ? BoxDecoration(
                        border: Border.all(color: AppColors.danger, width: 2),
                        borderRadius: BorderRadius.circular(10.r),
                      )
                    : null,
                child: AppImagePicker(
                  label: AppStrings.tournamentBanner,
                  initialImageUrl: widget.tournament?.bannerUrl,
                  onImageSelected: (bytes, name) {
                    setState(() {
                      _bannerBytes = bytes;
                      _bannerName = name;
                      _bannerError = false;
                    });
                  },
                ),
              ),
              if (_bannerError) ...[
                SizedBox(height: 4.h),
                Text(
                  AppStrings.tournamentBannerRequired,
                  style: TextStyle(color: AppColors.danger, fontSize: 12.sp),
                ),
              ],
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _titleArController,
                      label: 'عنوان البطولة (بالعربية)',
                      validator: (v) => v == null || v.trim().isEmpty ? AppStrings.fieldRequired : null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: AppTextField(
                      controller: _titleEnController,
                      label: 'عنوان البطولة (بالإنجليزية)',
                    ),
                  ),
                ],
              ),

              // 2. Game & Bracket Settings Section
              _buildSectionHeader('إعدادات اللعبة والقرعة', Icons.sports_esports_rounded),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _gameTitleController,
                      label: AppStrings.gameTitle,
                      validator: (v) => v == null || v.trim().isEmpty ? AppStrings.fieldRequired : null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.treeSize,
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                        ),
                        SizedBox(height: 8.h),
                        DropdownButtonFormField<int>(
                          initialValue: _treeSize,
                          dropdownColor: AppColors.cardBackground,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.mutedBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: const BorderSide(color: AppColors.borderDefault),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 8, child: Text('8 لاعبين')),
                            DropdownMenuItem(value: 16, child: Text('16 لاعب')),
                            DropdownMenuItem(value: 32, child: Text('32 لاعب')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _treeSize = val;
                                _maxPlayersController.text = val.toString();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _entryFeeController,
                      label: '${AppStrings.entryFee} (EGP / ج.م)',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return AppStrings.fieldRequired;
                        if (double.tryParse(v.trim()) == null) return 'أدخل مبلغاً صحيحاً';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: AppTextField(
                      controller: _prizePoolController,
                      label: '${AppStrings.prizePool} (EGP / ج.م)',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return AppStrings.fieldRequired;
                        if (double.tryParse(v.trim()) == null) return 'أدخل مبلغاً صحيحاً';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _minPlayersController,
                      label: AppStrings.minPlayers,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final val = int.tryParse(v?.trim() ?? '');
                        if (val == null || val <= 0) return 'أدخل أدنى عدد صحيح';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: AppTextField(
                      controller: _maxPlayersController,
                      label: '${AppStrings.maxPlayers} (بحد أقصى $_treeSize)',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final val = int.tryParse(v?.trim() ?? '');
                        if (val == null || val <= 0) return 'أدخل أقصى عدد صحيح';
                        if (val > _treeSize) return 'يتجاوز حجم الشجرة ($_treeSize)';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              // 3. Schedule Section
              _buildSectionHeader(AppStrings.schedule, Icons.access_time_filled_rounded),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Wrap(
                  spacing: 16.w,
                  runSpacing: 16.h,
                  children: [
                    SizedBox(
                      width: 320.w,
                      child: _buildDateTimeField(AppStrings.regOpensAt, _registrationOpensAt, (d) => setState(() => _registrationOpensAt = d)),
                    ),
                    SizedBox(
                      width: 320.w,
                      child: _buildDateTimeField(AppStrings.regClosesAt, _registrationClosesAt, (d) => setState(() => _registrationClosesAt = d)),
                    ),
                    SizedBox(
                      width: 320.w,
                      child: _buildDateTimeField(AppStrings.checkInOpensAt, _checkInOpensAt, (d) => setState(() => _checkInOpensAt = d)),
                    ),
                    SizedBox(
                      width: 320.w,
                      child: _buildDateTimeField(AppStrings.startDate, _startDate, (d) => setState(() => _startDate = d)),
                    ),
                  ],
                ),
              ),

              // 4. Descriptions & Rules Section
              _buildSectionHeader('الوصف والقواعد والتعليمات', Icons.description_rounded),
              AppTextField(
                controller: _rulesArController,
                label: 'الوصف والقواعد (بالعربية)',
                maxLines: 3,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                controller: _rulesEnController,
                label: 'Description & Rules (English)',
                maxLines: 3,
              ),

              // 5. Visibility Section
              _buildSectionHeader(AppStrings.visibilityScope, Icons.visibility_rounded),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _visibilityScope,
                      dropdownColor: AppColors.cardBackground,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.mutedBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(color: AppColors.borderDefault),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: 'all', child: Text(AppStrings.visibilityAll)),
                        DropdownMenuItem(value: 'city', child: Text(AppStrings.visibilityCity)),
                        DropdownMenuItem(value: 'radius', child: Text(AppStrings.visibilityRadius)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _visibilityScope = val;
                          });
                        }
                      },
                    ),
                  ),
                  if (_visibilityScope == 'city') ...[
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _loadingCities
                          ? SizedBox(
                              height: 48.h,
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.neonBlue),
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              initialValue: _cities.any((c) => c.id == _selectedCityId) ? _selectedCityId : null,
                              dropdownColor: AppColors.cardBackground,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.mutedBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: const BorderSide(color: AppColors.borderDefault),
                                ),
                              ),
                              hint: Text(AppStrings.selectCity, style: const TextStyle(color: AppColors.textSecondary)),
                              items: _cities.map((city) {
                                return DropdownMenuItem<String>(
                                  value: city.id,
                                  child: Text(city.nameAr.isNotEmpty ? city.nameAr : city.nameEn),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedCityId = val;
                                  });
                                }
                              },
                            ),
                    ),
                  ],
                  if (_visibilityScope == 'radius') ...[
                    SizedBox(width: 16.w),
                    Expanded(
                      child: AppTextField(
                        controller: _radiusController,
                        label: AppStrings.visibilityRadiusKm,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (_visibilityScope == 'radius') {
                            final val = double.tryParse(v?.trim() ?? '');
                            if (val == null || val <= 0) {
                              return AppStrings.radiusRequiredError;
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
