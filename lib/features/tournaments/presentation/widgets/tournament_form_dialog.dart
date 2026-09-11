import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../../../art_core/widgets/app_text_field.dart';
import '../../domain/entities/tournament_entity.dart';

class TournamentFormDialog extends StatefulWidget {
  final TournamentEntity? tournament;
  final Function(TournamentEntity) onSubmit;

  const TournamentFormDialog({
    super.key,
    this.tournament,
    required this.onSubmit,
  });

  @override
  State<TournamentFormDialog> createState() => _TournamentFormDialogState();
}

class _TournamentFormDialogState extends State<TournamentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _gameTitleController;
  late TextEditingController _entryFeeController;
  late TextEditingController _prizePoolController;
  late TextEditingController _minPlayersController;
  late TextEditingController _maxPlayersController;
  late TextEditingController _rulesController;

  int _treeSize = 16;
  DateTime _registrationOpensAt = DateTime.now();
  DateTime _registrationClosesAt = DateTime.now().add(const Duration(days: 5));
  DateTime _checkInOpensAt = DateTime.now().add(const Duration(days: 5, hours: 2));
  DateTime _checkInClosesAt = DateTime.now().add(const Duration(days: 7, hours: -1));
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 8));

  @override
  void initState() {
    super.initState();
    final t = widget.tournament;
    _titleController = TextEditingController(text: t?.title ?? '');
    _gameTitleController = TextEditingController(text: t?.gameTitle ?? 'EA FC 25');
    _entryFeeController = TextEditingController(text: t?.entryFee.toString() ?? '50');
    _prizePoolController = TextEditingController(text: t?.prizePool.toString() ?? '500');
    _minPlayersController = TextEditingController(text: t?.minPlayers.toString() ?? '4');
    _maxPlayersController = TextEditingController(text: t?.maxPlayers.toString() ?? '16');
    _rulesController = TextEditingController(text: t?.rules ?? '');

    if (t != null) {
      _treeSize = t.treeSize;
      _startDate = t.startDate;
      _endDate = t.endDate;
      _registrationOpensAt = t.registrationOpensAt ?? DateTime.now();
      _registrationClosesAt = t.registrationClosesAt ?? t.registrationDeadline;
      _checkInOpensAt = t.checkInOpensAt ?? t.registrationDeadline.add(const Duration(hours: 1));
      _checkInClosesAt = t.checkInClosesAt ?? t.startDate.subtract(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _gameTitleController.dispose();
    _entryFeeController.dispose();
    _prizePoolController.dispose();
    _minPlayersController.dispose();
    _maxPlayersController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, DateTime initial, Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
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
    if (picked != null) {
      onPicked(picked);
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      // Client Validations according to pre-launch checklist & spec
      if (_registrationClosesAt.isBefore(_registrationOpensAt) ||
          _registrationClosesAt.isAtSameMomentAs(_registrationOpensAt)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تاريخ إغلاق التسجيل يجب أن يكون بعد تاريخ فتح التسجيل'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      if (_checkInOpensAt.isBefore(_registrationClosesAt)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تاريخ فتح تسجيل الحضور (Check-in) يجب أن يكون بعد إغلاق التسجيل'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      if (_checkInClosesAt.isAfter(_startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تاريخ إغلاق تسجيل الحضور يجب أن يكون قبل انطلاق البطولة'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      if (_endDate.isBefore(_startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.endDate),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      final entity = TournamentEntity(
        id: widget.tournament?.id ?? '',
        title: _titleController.text.trim(),
        titleAr: _titleController.text.trim(),
        titleEn: _titleController.text.trim(),
        descriptionAr: _rulesController.text.trim(),
        descriptionEn: _rulesController.text.trim(),
        gameTitle: _gameTitleController.text.trim(),
        treeSize: _treeSize,
        status: widget.tournament?.status ?? TournamentStatus.draft,
        entryFee: double.tryParse(_entryFeeController.text.trim()) ?? 0.0,
        prizePool: double.tryParse(_prizePoolController.text.trim()) ?? 0.0,
        startDate: _startDate,
        endDate: _endDate,
        registrationDeadline: _registrationClosesAt,
        registrationOpensAt: _registrationOpensAt,
        registrationClosesAt: _registrationClosesAt,
        checkInOpensAt: _checkInOpensAt,
        checkInClosesAt: _checkInClosesAt,
        tournamentStartsAt: _startDate,
        minPlayers: int.tryParse(_minPlayersController.text.trim()) ?? 4,
        maxPlayers: int.tryParse(_maxPlayersController.text.trim()) ?? _treeSize,
        rules: _rulesController.text.trim(),
        registeredCount: widget.tournament?.registeredCount ?? 0,
        loungeId: widget.tournament?.loungeId,
        cityId: widget.tournament?.cityId,
      );

      widget.onSubmit(entity);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.tournament != null;
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return AppDialog(
      title: isEdit ? AppStrings.editTournament : AppStrings.createTournament,
      width: 700.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 12.w),
        AppButton(
          text: isEdit ? AppStrings.saveChanges : AppStrings.createTournament,
          onPressed: _handleSubmit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _titleController,
              label: AppStrings.tournamentTitle,
              validator: (v) => v == null || v.trim().isEmpty ? AppStrings.fieldRequired : null,
            ),
            SizedBox(height: 16.h),
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
                        value: _treeSize,
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
                          DropdownMenuItem(value: 8, child: Text('8')),
                          DropdownMenuItem(value: 16, child: Text('16')),
                          DropdownMenuItem(value: 32, child: Text('32')),
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
                    label: AppStrings.entryFee,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty ? AppStrings.fieldRequired : null,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: AppTextField(
                    controller: _prizePoolController,
                    label: AppStrings.prizePool,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty ? AppStrings.fieldRequired : null,
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
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: AppTextField(
                    controller: _maxPlayersController,
                    label: AppStrings.maxPlayers,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              AppStrings.schedule,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            // Schedule Dates Pickers
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [
                SizedBox(
                  width: 200.w,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.timer_outlined, color: AppColors.neonBlue),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('فتح التسجيل', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
                        Text(dateFormat.format(_registrationOpensAt), style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp)),
                      ],
                    ),
                    onPressed: () => _selectDate(context, _registrationOpensAt, (d) => setState(() => _registrationOpensAt = d)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                      side: const BorderSide(color: AppColors.borderDefault),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200.w,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.timer_off_outlined, color: AppColors.warning),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('غلق التسجيل', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
                        Text(dateFormat.format(_registrationClosesAt), style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp)),
                      ],
                    ),
                    onPressed: () => _selectDate(context, _registrationClosesAt, (d) => setState(() => _registrationClosesAt = d)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                      side: const BorderSide(color: AppColors.borderDefault),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200.w,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, color: AppColors.neonBlue),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('فتح الحضور (Check-in)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
                        Text(dateFormat.format(_checkInOpensAt), style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp)),
                      ],
                    ),
                    onPressed: () => _selectDate(context, _checkInOpensAt, (d) => setState(() => _checkInOpensAt = d)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                      side: const BorderSide(color: AppColors.borderDefault),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200.w,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.play_circle_fill, color: AppColors.success),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('انطلاق البطولة', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
                        Text(dateFormat.format(_startDate), style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp)),
                      ],
                    ),
                    onPressed: () => _selectDate(context, _startDate, (d) => setState(() => _startDate = d)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                      side: const BorderSide(color: AppColors.borderDefault),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200.w,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.flag_outlined, color: AppColors.danger),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('انتهاء البطولة', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
                        Text(dateFormat.format(_endDate), style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp)),
                      ],
                    ),
                    onPressed: () => _selectDate(context, _endDate, (d) => setState(() => _endDate = d)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                      side: const BorderSide(color: AppColors.borderDefault),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            AppTextField(
              controller: _rulesController,
              label: AppStrings.rules,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
