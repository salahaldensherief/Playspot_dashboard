import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_match_entity.dart';

class TournamentBracketView extends StatelessWidget {
  final TournamentEntity? tournament;
  final List<TournamentMatchEntity> matches;
  final VoidCallback onDrawBracket;
  final Function(TournamentMatchEntity match) onStartMatch;

  const TournamentBracketView({
    super.key,
    this.tournament,
    required this.matches,
    required this.onDrawBracket,
    required this.onStartMatch,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      final canDraw = tournament?.canDrawBracket ?? false;

      return Container(
        padding: EdgeInsets.all(40.r),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_tree_outlined, size: 64.r, color: AppColors.neonBlue),
              SizedBox(height: 16.h),
              Text(
                AppStrings.drawBracket,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                '${AppStrings.users}: ${tournament?.registeredCount ?? 0} / ${tournament?.minPlayers ?? 4}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),
              AppButton(
                text: AppStrings.drawBracket,
                icon: Icons.shuffle,
                onPressed: canDraw ? onDrawBracket : null,
              ),
            ],
          ),
        ),
      );
    }

    // Group matches by round
    final Map<int, List<TournamentMatchEntity>> rounds = {};
    for (var m in matches) {
      rounds.putIfAbsent(m.round, () => []).add(m);
    }

    final sortedRounds = rounds.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.drawBracket,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            AppButton(
              text: AppStrings.refresh,
              variant: AppButtonVariant.outlined,
              icon: Icons.refresh,
              onPressed: onDrawBracket,
            ),
          ],
        ),
        SizedBox(height: 20.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sortedRounds.map((r) {
              final roundMatches = rounds[r]!;
              return _buildRoundColumn(context, r, sortedRounds.length, roundMatches);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRoundColumn(
    BuildContext context,
    int roundNumber,
    int totalRounds,
    List<TournamentMatchEntity> roundMatches,
  ) {
    String roundTitle = 'جولة $roundNumber';
    if (roundNumber == totalRounds) {
      roundTitle = 'النهائي (Final 🏆)';
    } else if (roundNumber == totalRounds - 1) {
      roundTitle = 'نصف النهائي (Semi-Final)';
    } else if (roundNumber == totalRounds - 2) {
      roundTitle = 'ربع النهائي (Quarter-Final)';
    }

    return Container(
      width: 260.w,
      margin: EdgeInsets.only(left: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppColors.mutedBackground,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.neonBlue.withAlpha(80)),
            ),
            child: Text(
              roundTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.neonBlue,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          ...roundMatches.map((m) => _buildMatchCard(context, m)),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, TournamentMatchEntity match) {
    final bool p1Won = match.winnerId != null && match.winnerId == match.player1Id;
    final bool p2Won = match.winnerId != null && match.winnerId == match.player2Id;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: match.isDisputed
            ? AppColors.danger.withAlpha(20)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: match.isDisputed
              ? AppColors.danger
              : (match.isCompleted ? AppColors.success.withAlpha(100) : AppColors.borderDefault),
          width: match.isDisputed ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مباراة #${match.matchNumber}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
              if (match.isBye)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(color: Colors.blue.withAlpha(30), borderRadius: BorderRadius.circular(4.r)),
                  child: Text('Bye', style: TextStyle(color: Colors.blue, fontSize: 10.sp)),
                )
              else if (match.isDisputed)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(color: AppColors.danger.withAlpha(30), borderRadius: BorderRadius.circular(4.r)),
                  child: Text('نزاع ⚠️', style: TextStyle(color: AppColors.danger, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          // Player 1
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: p1Won ? AppColors.success.withAlpha(30) : Colors.transparent,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    match.player1Name ?? 'P1',
                    style: TextStyle(
                      color: match.player1Name != null ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 13.sp,
                      fontWeight: p1Won ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${match.player1Score}',
                  style: TextStyle(
                    color: p1Won ? AppColors.success : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.borderDefault, height: 12),
          // Player 2
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: p2Won ? AppColors.success.withAlpha(30) : Colors.transparent,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    match.player2Name ?? 'P2',
                    style: TextStyle(
                      color: match.player2Name != null ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 13.sp,
                      fontWeight: p2Won ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${match.player2Score}',
                  style: TextStyle(
                    color: p2Won ? AppColors.success : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          if (match.isScheduled && !match.isBye) ...[
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: AppStrings.startSession,
                fontSize: 11.sp,
                padding: EdgeInsets.symmetric(vertical: 4.h),
                variant: AppButtonVariant.outlined,
                onPressed: () => onStartMatch(match),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
