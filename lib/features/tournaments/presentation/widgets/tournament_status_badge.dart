import 'package:flutter/material.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/status_badge.dart';
import '../../domain/entities/tournament_entity.dart';

class TournamentStatusBadge extends StatelessWidget {
  final TournamentStatus status;

  const TournamentStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TournamentStatus.published:
        return StatusBadge(text: AppStrings.active, color: AppColors.success);
      case TournamentStatus.inProgress:
        return StatusBadge(text: AppStrings.inProgress, color: AppColors.neonBlue);
      case TournamentStatus.completed:
        return StatusBadge(text: AppStrings.completed, color: Colors.blue);
      case TournamentStatus.cancelled:
        return StatusBadge(text: AppStrings.cancelled, color: AppColors.danger);
      case TournamentStatus.draft:
        return StatusBadge(text: AppStrings.pending, color: AppColors.warning);
      case TournamentStatus.registrationOpen:
      case TournamentStatus.registrationClosed:
      case TournamentStatus.checkInOpen:
      case TournamentStatus.checkInClosed:
      case TournamentStatus.drawCompleted:
        return StatusBadge(text: status.name, color: AppColors.neonCyan);
    }
  }
}
