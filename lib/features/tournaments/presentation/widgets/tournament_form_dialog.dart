import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../../../art_core/widgets/app_image_picker.dart';
import '../../../../art_core/widgets/app_text_field.dart';
import '../../../../core/di/di.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_prize_entity.dart';
import 'tournament_basic_details_section.dart';
import 'tournament_prize_banner.dart';
import 'tournament_prizes_dialog.dart';
import 'tournament_schedule_section.dart';

class TournamentFormDialog extends StatefulWidget {
  final TournamentEntity? tournament;
  final String? loungeId;
  final Function(TournamentEntity) onSubmit;

  const TournamentFormDialog({
    super.key,
    this.tournament,
    this.loungeId,
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

  Uint8List? _bannerBytes;
  String? _bannerName;
  bool _isUploading = false;

  int _treeSize = 16;
  DateTime _registrationOpensAt = DateTime.now();
  DateTime _registrationClosesAt = DateTime.now().add(const Duration(days: 5));
  DateTime _checkInOpensAt = DateTime.now().add(const Duration(days: 5, hours: 2));
  DateTime _checkInClosesAt = DateTime.now().add(const Duration(days: 7, hours: -1));
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 8));
  List<TournamentPrizeEntity> _prizes = [];

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
      _prizes = t.prizes;
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

  bool _validateTimeline() {
    if (widget.tournament == null && _bannerBytes == null) {
      _showError(AppStrings.tournamentBannerRequired);
      return false;
    }
    if (_registrationClosesAt.isBefore(_registrationOpensAt) ||
        _registrationClosesAt.isAtSameMomentAs(_registrationOpensAt)) {
      _showError(AppStrings.regCloseAfterOpenError);
      return false;
    }
    if (_checkInOpensAt.isBefore(_registrationClosesAt)) {
      _showError(AppStrings.checkInAfterRegCloseError);
      return false;
    }
    if (_checkInClosesAt.isAfter(_startDate)) {
      _showError(AppStrings.checkInBeforeStartError);
      return false;
    }
    if (_endDate.isBefore(_startDate)) {
      _showError(AppStrings.endDate);
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_validateTimeline()) return;

    setState(() => _isUploading = true);

    try {
      String? bannerUrl = widget.tournament?.bannerUrl;
      final tournamentId = widget.tournament?.id ?? const Uuid().v4();

      if (_bannerBytes != null && _bannerName != null) {
        bannerUrl = await sl<StorageService>().uploadTournamentBanner(
          _bannerBytes!,
          _bannerName!,
          tournamentId,
        );
      }

      if (mounted) {
        final entity = TournamentEntity(
          id: widget.tournament?.id ?? tournamentId,
          title: _titleController.text.trim(),
          titleAr: _titleController.text.trim(),
          titleEn: _titleController.text.trim(),
          descriptionAr: _rulesController.text.trim(),
          descriptionEn: _rulesController.text.trim(),
          gameTitle: _gameTitleController.text.trim(),
          bannerUrl: bannerUrl,
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
          prizes: _prizes,
          loungeId: widget.tournament?.loungeId ?? widget.loungeId,
          cityId: widget.tournament?.cityId,
        );

        widget.onSubmit(entity);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('${AppStrings.error}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _openManagePrizes() {
    final currentEntity = TournamentEntity(
      id: widget.tournament?.id ?? const Uuid().v4(),
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'البطولة',
      treeSize: _treeSize,
      status: widget.tournament?.status ?? TournamentStatus.draft,
      entryFee: double.tryParse(_entryFeeController.text.trim()) ?? 0.0,
      prizePool: double.tryParse(_prizePoolController.text.trim()) ?? 0.0,
      startDate: _startDate,
      endDate: _endDate,
      registrationDeadline: _registrationClosesAt,
      minPlayers: int.tryParse(_minPlayersController.text.trim()) ?? 4,
      maxPlayers: int.tryParse(_maxPlayersController.text.trim()) ?? _treeSize,
      prizes: _prizes,
      loungeId: widget.tournament?.loungeId ?? widget.loungeId,
    );
    showDialog(
      context: context,
      builder: (ctx) => TournamentPrizesDialog(
        tournament: currentEntity,
        onSave: (updated) => setState(() => _prizes = updated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.tournament != null;

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
          isLoading: _isUploading,
          onPressed: _handleSubmit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppImagePicker(
              label: AppStrings.tournamentBanner,
              initialImageUrl: widget.tournament?.bannerUrl,
              onImageSelected: (bytes, name) {
                setState(() {
                  _bannerBytes = bytes;
                  _bannerName = name;
                });
              },
            ),
            SizedBox(height: 16.h),
            TournamentBasicDetailsSection(
              titleController: _titleController,
              gameTitleController: _gameTitleController,
              entryFeeController: _entryFeeController,
              prizePoolController: _prizePoolController,
              treeSize: _treeSize,
              onTreeSizeChanged: (val) {
                if (val != null) {
                  setState(() {
                    _treeSize = val;
                    _maxPlayersController.text = val.toString();
                  });
                }
              },
            ),
            SizedBox(height: 12.h),
            TournamentPrizeBanner(
              prizeCount: _prizes.length,
              onManagePrizes: _openManagePrizes,
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
            TournamentScheduleSection(
              registrationOpensAt: _registrationOpensAt,
              registrationClosesAt: _registrationClosesAt,
              checkInOpensAt: _checkInOpensAt,
              startDate: _startDate,
              endDate: _endDate,
              onRegistrationOpensChanged: (d) => setState(() => _registrationOpensAt = d),
              onRegistrationClosesChanged: (d) => setState(() => _registrationClosesAt = d),
              onCheckInOpensChanged: (d) => setState(() => _checkInOpensAt = d),
              onStartDateChanged: (d) => setState(() => _startDate = d),
              onEndDateChanged: (d) => setState(() => _endDate = d),
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
