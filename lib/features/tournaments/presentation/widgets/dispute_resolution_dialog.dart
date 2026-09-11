import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_cached_image.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../../../art_core/widgets/app_text_field.dart';
import '../../domain/entities/tournament_match_entity.dart';

class DisputeResolutionDialog extends StatefulWidget {
  final TournamentMatchEntity match;
  final Function({
    required String winnerId,
    required int p1Score,
    required int p2Score,
    required String resolutionNotes,
  }) onResolve;

  const DisputeResolutionDialog({
    super.key,
    required this.match,
    required this.onResolve,
  });

  @override
  State<DisputeResolutionDialog> createState() => _DisputeResolutionDialogState();
}

class _DisputeResolutionDialogState extends State<DisputeResolutionDialog> {
  late TextEditingController _p1ScoreController;
  late TextEditingController _p2ScoreController;
  late TextEditingController _notesController;
  String? _selectedWinnerId;

  @override
  void initState() {
    super.initState();
    _p1ScoreController = TextEditingController(text: widget.match.player1Score.toString());
    _p2ScoreController = TextEditingController(text: widget.match.player2Score.toString());
    _notesController = TextEditingController();
    _selectedWinnerId = widget.match.player1Id;
  }

  @override
  void dispose() {
    _p1ScoreController.dispose();
    _p2ScoreController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final winnerId = _selectedWinnerId;
    final p1Score = int.tryParse(_p1ScoreController.text.trim()) ?? 0;
    final p2Score = int.tryParse(_p2ScoreController.text.trim()) ?? 0;
    final notes = _notesController.text.trim();

    if (winnerId == null || winnerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد الفائز بالمباراة'), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة ملاحظات القرار الإداري (Resolution Notes)'), backgroundColor: AppColors.danger),
      );
      return;
    }

    widget.onResolve(
      winnerId: winnerId,
      p1Score: p1Score,
      p2Score: p2Score,
      resolutionNotes: notes,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;

    return AppDialog(
      title: '${AppStrings.disputesRoom} #${m.matchNumber}',
      width: 600.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 12.w),
        AppButton(
          text: AppStrings.resolveDispute,
          backgroundColor: AppColors.success,
          onPressed: _handleSubmit,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player match info
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.mutedBackground,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('اللاعب الأول', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
                    SizedBox(height: 4.h),
                    Text(m.player1Name ?? 'P1', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  ],
                ),
                Text('VS', style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold, fontSize: 18.sp)),
                Column(
                  children: [
                    Text('اللاعب الثاني', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
                    SizedBox(height: 4.h),
                    Text(m.player2Name ?? 'P2', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          if (m.disputeReason != null && m.disputeReason!.isNotEmpty) ...[
            Text('سبب النزاع:', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 14.sp)),
            SizedBox(height: 6.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(20),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.danger.withAlpha(80)),
              ),
              child: Text(m.disputeReason!, style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp)),
            ),
            SizedBox(height: 16.h),
          ],
          if (m.proofUrl != null && m.proofUrl!.isNotEmpty) ...[
            Text('صورة الإثبات:', style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp)),
            SizedBox(height: 6.h),
            Container(
              height: 220.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.mutedBackground,
                borderRadius: BorderRadius.circular(8.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: AppCachedImage(imageUrl: m.proofUrl!, fit: BoxFit.contain),
            ),
            SizedBox(height: 20.h),
          ],
          Text('تحديد الفائز والسكور النهائي', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15.sp)),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text(m.player1Name ?? 'P1', style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp)),
                  value: m.player1Id ?? '',
                  groupValue: _selectedWinnerId,
                  onChanged: (val) => setState(() => _selectedWinnerId = val),
                  activeColor: AppColors.neonBlue,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text(m.player2Name ?? 'P2', style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp)),
                  value: m.player2Id ?? '',
                  groupValue: _selectedWinnerId,
                  onChanged: (val) => setState(() => _selectedWinnerId = val),
                  activeColor: AppColors.neonBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _p1ScoreController,
                  label: m.player1Name ?? 'P1',
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: AppTextField(
                  controller: _p2ScoreController,
                  label: m.player2Name ?? 'P2',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          AppTextField(
            controller: _notesController,
            label: AppStrings.reviewNotes,
            hintText: 'ملاحظات القرار الإداري',
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
