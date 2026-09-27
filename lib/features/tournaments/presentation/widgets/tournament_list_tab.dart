import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/section_container.dart';
import '../../domain/entities/tournament_entity.dart';
import 'tournament_card.dart';

class TournamentListTab extends StatelessWidget {
  final List<TournamentEntity> tournaments;
  final TournamentEntity? selectedTournament;
  final ValueChanged<TournamentEntity> onSelect;
  final ValueChanged<TournamentEntity> onManagePrizes;
  final ValueChanged<TournamentEntity> onEdit;
  final ValueChanged<TournamentEntity> onDelete;

  const TournamentListTab({
    super.key,
    required this.tournaments,
    required this.selectedTournament,
    required this.onSelect,
    required this.onManagePrizes,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) {
      return SectionContainer(
        title: AppStrings.tournaments,
        children: [
          Center(
            child: Text(
              AppStrings.noTournaments,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final t = tournaments[index];
        final isSelected = selectedTournament?.id == t.id;

        return TournamentCard(
          key: ValueKey(t.id),
          tournament: t,
          isSelected: isSelected,
          onSelect: () => onSelect(t),
          onManagePrizes: () => onManagePrizes(t),
          onEdit: () => onEdit(t),
          onDelete: () => onDelete(t),
        );
      },
    );
  }
}
