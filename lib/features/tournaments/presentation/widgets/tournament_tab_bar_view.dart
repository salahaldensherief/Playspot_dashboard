import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/tournament_entity.dart';
import '../tournament_cubit.dart';
import '../tournament_matches_cubit.dart';
import '../tournament_matches_state.dart';
import '../tournament_participants_cubit.dart';
import '../tournament_participants_state.dart';
import '../tournament_state.dart';
import 'dispute_resolution_dialog.dart';
import 'tournament_audit_logs_tab.dart';
import 'tournament_bracket_view.dart';
import 'tournament_disputes_tab.dart';
import 'tournament_list_tab.dart';
import 'tournament_participants_table.dart';

class TournamentTabBarView extends StatelessWidget {
  final TabController tabController;
  final TournamentState state;
  final TournamentEntity? selected;
  final ValueChanged<TournamentEntity> onManagePrizes;
  final ValueChanged<TournamentEntity> onEdit;
  final ValueChanged<TournamentEntity> onDelete;

  const TournamentTabBarView({
    super.key,
    required this.tabController,
    required this.state,
    required this.selected,
    required this.onManagePrizes,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: [
        TournamentListTab(
          tournaments: state.tournaments,
          selectedTournament: selected,
          onSelect: (t) => context.read<TournamentCubit>().selectTournament(t),
          onManagePrizes: onManagePrizes,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        BlocBuilder<TournamentParticipantsCubit, TournamentParticipantsState>(
          builder: (context, partState) {
            return TournamentParticipantsTable(
              participants: partState.participants,
              onApprovePayment: (p) =>
                  context.read<TournamentParticipantsCubit>().approvePayment(p.id),
              onRejectPayment: (p, reason) =>
                  context.read<TournamentParticipantsCubit>().rejectPayment(p.id, reason),
              onRecordCash: (p) =>
                  context.read<TournamentParticipantsCubit>().recordCashPayment(p.id),
              onCheckIn: (p) =>
                  context.read<TournamentParticipantsCubit>().checkInParticipant(p.id),
              onWithdraw: (p) =>
                  context.read<TournamentParticipantsCubit>().withdrawParticipant(p.id),
            );
          },
        ),
        BlocBuilder<TournamentMatchesCubit, TournamentMatchesState>(
          builder: (context, matchState) {
            return tabController.index == 2
                ? TournamentBracketView(
                    tournament: selected,
                    matches: matchState.matches,
                    onDrawBracket: () {
                      if (selected != null) {
                        context.read<TournamentMatchesCubit>().drawBracket(selected!.id);
                      }
                    },
                    onStartMatch: (m) {
                      if (selected != null) {
                        context.read<TournamentMatchesCubit>().startMatch(m.id, selected!.id);
                      }
                    },
                  )
                : const SizedBox.shrink();
          },
        ),
        BlocBuilder<TournamentMatchesCubit, TournamentMatchesState>(
          builder: (context, matchState) {
            return TournamentDisputesTab(
              disputedMatches: matchState.disputedMatches,
              onResolveDispute: (m) {
                showDialog(
                  context: context,
                  builder: (ctx) => DisputeResolutionDialog(
                    match: m,
                    onResolve: ({
                      required winnerId,
                      required p1Score,
                      required p2Score,
                      required resolutionNotes,
                    }) {
                      if (selected != null) {
                        context.read<TournamentMatchesCubit>().resolveDispute(
                              m.id,
                              selected!.id,
                              winnerId: winnerId,
                              p1Score: p1Score,
                              p2Score: p2Score,
                              resolutionNotes: resolutionNotes,
                            );
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
        TournamentAuditLogsTab(auditLogs: state.auditLogs),
      ],
    );
  }
}
