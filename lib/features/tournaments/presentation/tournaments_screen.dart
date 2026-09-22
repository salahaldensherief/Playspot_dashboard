import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../art_core/app_strings.dart';
import '../../../art_core/layouts/dashboard_layout.dart';
import '../../../art_core/theme/app_colors.dart';
import '../../../art_core/widgets/app_button.dart';
import '../../../art_core/widgets/app_dialog.dart';
import '../../../art_core/widgets/section_container.dart';
import '../../../art_core/widgets/status_badge.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../auth/presentation/login/login_cubit.dart';
import '../domain/entities/tournament_entity.dart';
import 'tournament_cubit.dart';
import 'tournament_state.dart';
import 'tournament_participants_cubit.dart';
import 'tournament_participants_state.dart';
import 'tournament_matches_cubit.dart';
import 'tournament_matches_state.dart';
import 'widgets/audit_logs_modal.dart';
import 'widgets/dispute_resolution_dialog.dart';
import 'widgets/tournament_bracket_view.dart';
import 'widgets/tournament_form_dialog.dart';
import 'widgets/tournament_participants_table.dart';
import 'widgets/tournament_prizes_dialog.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<TournamentCubit>().setTab(_tabController.index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loungeId = context.read<LoginCubit>().state.userLounge?.id ??
          context.read<LoginCubit>().state.user?.loungeId;
      context.read<TournamentCubit>().loadTournaments(loungeId: loungeId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateDialog() {
    final activeLoungeId = context.read<LoginCubit>().state.userLounge?.id ??
        context.read<LoginCubit>().state.user?.loungeId;
    showDialog(
      context: context,
      builder: (ctx) => TournamentFormDialog(
        loungeId: activeLoungeId,
        onSubmit: (entity) {
          context.read<TournamentCubit>().createTournament(entity);
        },
      ),
    );
  }

  void _openEditDialog(TournamentEntity tournament) {
    showDialog(
      context: context,
      builder: (ctx) => TournamentFormDialog(
        tournament: tournament,
        onSubmit: (entity) {
          context.read<TournamentCubit>().updateTournament(entity);
        },
      ),
    );
  }

  void _openPrizesDialog(TournamentEntity tournament) {
    showDialog(
      context: context,
      builder: (ctx) => TournamentPrizesDialog(
        tournament: tournament,
        onSave: (prizes) {
          context.read<TournamentCubit>().saveTournamentPrizes(tournament.id, prizes);
        },
      ),
    );
  }

  void _confirmCancel(TournamentEntity tournament) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text(AppStrings.cancelTournament, style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${AppStrings.cancelTournament} "${tournament.title}"؟', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
            SizedBox(height: 12.h),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: AppStrings.reasonOrNote,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.mutedBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ],
        ),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.outlined,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppButton(
            text: AppStrings.cancelTournament,
            variant: AppButtonVariant.danger,
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<TournamentCubit>().cancelTournament(tournament.id, reasonController.text.trim());
    }
  }

  void _confirmDeleteDraft(TournamentEntity tournament) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppStrings.deleteDraft,
      message: '${AppStrings.deleteWarning} "${tournament.title}"؟',
      confirmText: AppStrings.deleteDraft,
      confirmColor: AppColors.danger,
    );

    if (confirmed == true && mounted) {
      context.read<TournamentCubit>().deleteDraftTournament(tournament.id);
    }
  }

  void _confirmDelete(TournamentEntity tournament) async {
    if (tournament.isCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('البطولة ملغاة بالفعل، وسجلاتها ومشاركوها محفوظون.'),
          backgroundColor: AppColors.neonBlue,
        ),
      );
      return;
    }

    if (tournament.isDraft && tournament.registeredCount == 0) {
      _confirmDeleteDraft(tournament);
      return;
    }

    // If published, active, or has participants/matches: prompt for cancellation reason
    _confirmCancel(tournament);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TournamentCubit, TournamentState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == TournamentCubitStatus.actionSuccess && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state.status == TournamentCubitStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      buildWhen: (prev, curr) =>
          prev.tournaments != curr.tournaments ||
          prev.selectedTournament != curr.selectedTournament ||
          prev.participants != curr.participants ||
          prev.matches != curr.matches ||
          prev.disputedMatches != curr.disputedMatches ||
          prev.auditLogs != curr.auditLogs ||
          prev.status != curr.status,
      builder: (context, state) {
        final selected = state.selectedTournament;
        final disputedCount = state.disputedMatches.length;

        return DashboardLayout(
          activeRoute: '/super-admin/tournaments',
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.isDesktop(context) ? 24.r : 16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (Adaptive)
                if (AppBreakpoints.isMobile(context))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tournamentsHub,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        AppStrings.tournamentsHubSub,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: AppStrings.refresh,
                              variant: AppButtonVariant.outlined,
                              icon: Icons.refresh,
                              onPressed: () {
                                final loungeId = context.read<LoginCubit>().state.userLounge?.id ??
                                    context.read<LoginCubit>().state.user?.loungeId;
                                context.read<TournamentCubit>().loadTournaments(loungeId: loungeId);
                              },
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: AppButton(
                              text: AppStrings.createTournament,
                              icon: Icons.add,
                              onPressed: _openCreateDialog,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.tournamentsHub,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              AppStrings.tournamentsHubSub,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Row(
                        children: [
                          AppButton(
                            text: AppStrings.refresh,
                            variant: AppButtonVariant.outlined,
                            icon: Icons.refresh,
                            onPressed: () {
                              final loungeId = context.read<LoginCubit>().state.userLounge?.id ??
                                  context.read<LoginCubit>().state.user?.loungeId;
                              context.read<TournamentCubit>().loadTournaments(loungeId: loungeId);
                            },
                          ),
                          SizedBox(width: 12.w),
                          AppButton(
                            text: AppStrings.createTournament,
                            icon: Icons.add,
                            onPressed: _openCreateDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                SizedBox(height: 16.h),
                if (state.status == TournamentCubitStatus.loading) ...[
                  LinearProgressIndicator(
                    color: AppColors.neonBlue,
                    backgroundColor: AppColors.mutedBackground,
                  ),
                  SizedBox(height: 16.h),
                ],

                // Prominent Open Disputes Alert Banner
                if (disputedCount > 0) ...[
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withAlpha(25),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.danger, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppStrings.disputesRoom}: $disputedCount ${AppStrings.pendingRequests}',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '${AppStrings.resolveDispute} ${state.disputedMatches.first.player1Name ?? "P1"} vs ${state.disputedMatches.first.player2Name ?? "P2"}',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
                              ),
                            ],
                          ),
                        ),
                        AppButton(
                          text: AppStrings.resolveDispute,
                          backgroundColor: AppColors.danger,
                          onPressed: () {
                            _tabController.animateTo(3); // Switch to Disputes tab
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Active Tournament Selector Dropdown
                if (state.tournaments.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Row(
                      children: [
                        Text('${AppStrings.tournaments}: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selected?.id,
                              dropdownColor: AppColors.cardBackground,
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.bold),
                              items: state.tournaments.map((t) {
                                return DropdownMenuItem(
                                  value: t.id,
                                  child: Text('${t.title} (${t.gameTitle ?? "eSports"}) - ${t.registeredCount}/${t.maxPlayers}'),
                                );
                              }).toList(),
                              onChanged: (id) {
                                final found = state.tournaments.where((t) => t.id == id).firstOrNull;
                                if (found != null) {
                                  context.read<TournamentCubit>().selectTournament(found);
                                  context.read<TournamentParticipantsCubit>().loadParticipants(found.id);
                                  context.read<TournamentMatchesCubit>().loadMatches(found.id);
                                  context.read<TournamentMatchesCubit>().startWatchingDisputes(found.id);
                                }
                              },
                            ),
                          ),
                        ),
                        if (selected != null) ...[
                          _buildTournamentStatusBadge(selected.status),
                          SizedBox(width: 8.w),
                          AppButton(
                            text: AppStrings.managePrizes,
                            icon: Icons.emoji_events_outlined,
                            variant: AppButtonVariant.outlined,
                            fontSize: 12.sp,
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            onPressed: () => _openPrizesDialog(selected),
                          ),
                          SizedBox(width: 8.w),
                          if (selected.isDraft) ...[
                            AppButton(
                              text: AppStrings.publishTournament,
                              backgroundColor: AppColors.success,
                              fontSize: 12.sp,
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              onPressed: () => context.read<TournamentCubit>().publishTournament(selected.id),
                            ),
                            SizedBox(width: 8.w),
                            if (selected.registeredCount == 0)
                              AppButton(
                                text: AppStrings.deleteDraft,
                                variant: AppButtonVariant.danger,
                                fontSize: 12.sp,
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                onPressed: () => _confirmDeleteDraft(selected),
                              )
                            else
                              AppButton(
                                text: AppStrings.cancelTournament,
                                variant: AppButtonVariant.danger,
                                fontSize: 12.sp,
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                onPressed: () => _confirmCancel(selected),
                              ),
                          ] else if (!selected.isCancelled) ...[
                            AppButton(
                              text: AppStrings.cancelTournament,
                              variant: AppButtonVariant.danger,
                              fontSize: 12.sp,
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              onPressed: () => _confirmCancel(selected),
                            ),
                            if (selected.isInProgress) ...[
                              SizedBox(width: 8.w),
                              AppButton(
                                text: AppStrings.completeBooking,
                                backgroundColor: AppColors.neonBlue,
                                fontSize: 12.sp,
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                onPressed: () => context.read<TournamentCubit>().awardPrizes(selected.id),
                              ),
                            ],
                          ],
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],

                // Navigation Tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppColors.neonBlue,
                  labelColor: AppColors.neonBlue,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [
                    Tab(text: AppStrings.tournaments),
                    Tab(text: '${AppStrings.users} (${state.participants.length})'),
                    Tab(text: AppStrings.drawBracket),
                    Tab(
                      child: Row(
                        children: [
                          Text(AppStrings.disputesRoom),
                          if (disputedCount > 0) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10.r)),
                              child: Text('$disputedCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(text: '${AppStrings.auditTrail} (${state.auditLogs.length})'),
                  ],
                ),
                SizedBox(height: 20.h),

                // Tab Views Content
                SizedBox(
                  height: 600.h,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 0: Tournaments Overview
                      _buildTournamentsListTab(context, state),
                      // Tab 1: Participants Table
                      BlocBuilder<TournamentParticipantsCubit, TournamentParticipantsState>(
                        builder: (context, partState) {
                          return TournamentParticipantsTable(
                            participants: partState.participants,
                            onApprovePayment: (p) => context.read<TournamentParticipantsCubit>().approvePayment(p.id),
                            onRejectPayment: (p, reason) => context.read<TournamentParticipantsCubit>().rejectPayment(p.id, reason),
                            onRecordCash: (p) => context.read<TournamentParticipantsCubit>().recordCashPayment(p.id),
                            onCheckIn: (p) => context.read<TournamentParticipantsCubit>().checkInParticipant(p.id),
                            onWithdraw: (p) => context.read<TournamentParticipantsCubit>().withdrawParticipant(p.id),
                          );
                        },
                      ),
                      // Tab 2: Bracket Tree (Lazy Built)
                      BlocBuilder<TournamentMatchesCubit, TournamentMatchesState>(
                        builder: (context, matchState) {
                          return _tabController.index == 2
                              ? TournamentBracketView(
                                  tournament: selected,
                                  matches: matchState.matches,
                                  onDrawBracket: () {
                                    if (selected != null) {
                                      context.read<TournamentMatchesCubit>().drawBracket(selected.id);
                                    }
                                  },
                                  onStartMatch: (m) {
                                    if (selected != null) {
                                      context.read<TournamentMatchesCubit>().startMatch(m.id, selected.id);
                                    }
                                  },
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                      // Tab 3: Disputes Room
                      BlocBuilder<TournamentMatchesCubit, TournamentMatchesState>(
                        builder: (context, matchState) {
                          return _buildDisputesRoomTab(context, matchState, selected);
                        },
                      ),
                      // Tab 4: Audit Trail
                      _buildAuditLogsTab(context, state),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTournamentsListTab(BuildContext context, TournamentState state) {
    if (state.tournaments.isEmpty) {
      return SectionContainer(
        title: AppStrings.tournaments,
        children: [
          Center(
            child: Text(AppStrings.noTournaments, style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp)),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: state.tournaments.length,
      itemBuilder: (context, index) {
        final t = state.tournaments[index];
        final isSelected = state.selectedTournament?.id == t.id;

        return Card(
          color: isSelected ? AppColors.neonBlue.withAlpha(15) : AppColors.cardBackground,
          margin: EdgeInsets.only(bottom: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
            side: BorderSide(color: isSelected ? AppColors.neonBlue : AppColors.borderDefault),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16.r),
            title: Row(
              children: [
                Text(t.title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                SizedBox(width: 12.w),
                _buildTournamentStatusBadge(t.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 6.h),
                Text('${AppStrings.gameTitle}: ${t.gameTitle ?? "eSports"} | ${AppStrings.entryFee}: ${t.entryFee} | ${AppStrings.prizePool}: ${t.prizePool}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
                SizedBox(height: 4.h),
                Text('${AppStrings.maxPlayers}: ${t.registeredCount} / ${t.maxPlayers} (${AppStrings.treeSize}: ${t.treeSize})', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
                if (t.prizes.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    children: t.prizes.map((p) {
                      final rewardsSummary = p.rewards.map((r) {
                        final icon = r.isTrophy
                            ? '🏆'
                            : r.isCash
                                ? '💵 ${r.value ?? ""} ${r.currency ?? "EGP"}'
                                : r.isPoints
                                    ? '⭐ ${r.value ?? ""} pts'
                                    : r.isVoucher
                                        ? '🎟️ ${r.value ?? ""}%'
                                        : '🎁';
                        final title = r.titleAr ?? r.title ?? icon;
                        return '$title ($icon)';
                      }).join(' + ');

                      final placementLabel = p.placement == 1
                          ? '🥇'
                          : p.placement == 2
                              ? '🥈'
                              : p.placement == 3
                                  ? '🥉'
                                  : '#${p.placement}';

                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.mutedBackground,
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: AppColors.borderDefault.withAlpha(80)),
                        ),
                        child: Text(
                          '$placementLabel $rewardsSummary',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  text: AppStrings.managePrizes,
                  icon: Icons.emoji_events_outlined,
                  variant: AppButtonVariant.outlined,
                  fontSize: 12.sp,
                  onPressed: () => _openPrizesDialog(t),
                ),
                SizedBox(width: 8.w),
                AppButton(
                  text: AppStrings.edit,
                  variant: AppButtonVariant.outlined,
                  fontSize: 12.sp,
                  onPressed: () => _openEditDialog(t),
                ),
                SizedBox(width: 8.w),
                AppButton(
                  text: AppStrings.deleteTournament,
                  variant: AppButtonVariant.danger,
                  fontSize: 12.sp,
                  onPressed: () => _confirmDelete(t),
                ),
                SizedBox(width: 8.w),
                AppButton(
                  text: AppStrings.viewAll,
                  fontSize: 12.sp,
                  onPressed: () {
                    context.read<TournamentCubit>().selectTournament(t);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDisputesRoomTab(BuildContext context, TournamentMatchesState state, TournamentEntity? selected) {
    if (state.disputedMatches.isEmpty) {
      return SectionContainer(
        title: AppStrings.disputesRoom,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                SizedBox(height: 12.h),
                Text(AppStrings.disputesRoom, style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: state.disputedMatches.length,
      itemBuilder: (context, index) {
        final m = state.disputedMatches[index];
        return Card(
          color: AppColors.danger.withAlpha(20),
          margin: EdgeInsets.only(bottom: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
            side: const BorderSide(color: AppColors.danger),
          ),
          child: ListTile(
            title: Text('${AppStrings.disputesRoom} #${m.matchNumber}', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 15.sp)),
            subtitle: Text('${m.player1Name ?? "P1"} vs ${m.player2Name ?? "P2"}\n${m.disputeReason ?? ""}', style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp)),
            trailing: AppButton(
              text: AppStrings.resolveDispute,
              backgroundColor: AppColors.danger,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => DisputeResolutionDialog(
                    match: m,
                    onResolve: ({required winnerId, required p1Score, required p2Score, required resolutionNotes}) {
                      if (selected != null) {
                        context.read<TournamentMatchesCubit>().resolveDispute(
                              m.id,
                              selected.id,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuditLogsTab(BuildContext context, TournamentState state) {
    return SectionContainer(
      title: AppStrings.auditTrail,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppStrings.auditTrail, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16.sp)),
            AppButton(
              text: AppStrings.viewAll,
              variant: AppButtonVariant.outlined,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AuditLogsModal(logs: state.auditLogs),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 400.h,
          child: ListView.builder(
            itemCount: state.auditLogs.length,
            itemBuilder: (context, index) {
              final log = state.auditLogs[index];
              return ListTile(
                title: Text(log.actionType, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp)),
                subtitle: Text(log.performedByName ?? log.performedBy, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentStatusBadge(TournamentStatus status) {
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
