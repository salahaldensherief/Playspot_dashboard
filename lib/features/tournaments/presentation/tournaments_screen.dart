import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../art_core/app_strings.dart';
import '../../../art_core/layouts/dashboard_layout.dart';
import '../../../art_core/theme/app_colors.dart';
import '../../../art_core/widgets/app_button.dart';
import '../../../core/responsive/responsive.dart';
import '../../auth/presentation/login/login_cubit.dart';
import '../domain/entities/tournament_entity.dart';
import 'tournament_cubit.dart';
import 'tournament_matches_cubit.dart';
import 'tournament_participants_cubit.dart';
import 'tournament_state.dart';
import 'widgets/tournament_disputes_alert_banner.dart';
import 'widgets/tournament_form_dialog.dart';
import 'widgets/tournament_header_bar.dart';
import 'widgets/tournament_prizes_dialog.dart';
import 'widgets/tournament_selector_bar.dart';
import 'widgets/tournament_tab_bar_view.dart';

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
      _refreshTournaments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshTournaments() {
    final loungeId = context.read<LoginCubit>().state.userLounge?.id ??
        context.read<LoginCubit>().state.user?.loungeId;
    context.read<TournamentCubit>().loadTournaments(loungeId: loungeId);
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
        title: Text(
          AppStrings.cancelTournament,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${AppStrings.cancelTournament} "${tournament.title}"؟',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text(
          AppStrings.deleteDraft,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${AppStrings.deleteWarning} "${tournament.title}"؟',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
        ),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.outlined,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppButton(
            text: AppStrings.deleteDraft,
            variant: AppButtonVariant.danger,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<TournamentCubit>().deleteDraftTournament(tournament.id);
    }
  }

  void _confirmDelete(TournamentEntity tournament) async {
    if (tournament.isCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tournamentCancelledInfo),
          backgroundColor: AppColors.neonBlue,
        ),
      );
      return;
    }

    if (tournament.isDraft && tournament.registeredCount == 0) {
      _confirmDeleteDraft(tournament);
      return;
    }

    _confirmCancel(tournament);
  }

  void _onSelectTournament(TournamentEntity found) {
    context.read<TournamentCubit>().selectTournament(found);
    context.read<TournamentParticipantsCubit>().loadParticipants(found.id);
    context.read<TournamentMatchesCubit>().loadMatches(found.id);
    context.read<TournamentMatchesCubit>().startWatchingDisputes(found.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TournamentCubit, TournamentState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == TournamentCubitStatus.actionSuccess && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!), backgroundColor: AppColors.success),
          );
        } else if (state.status == TournamentCubitStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.danger),
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
                TournamentHeaderBar(
                  onRefresh: _refreshTournaments,
                  onCreate: _openCreateDialog,
                ),
                SizedBox(height: 16.h),
                if (state.status == TournamentCubitStatus.loading) ...[
                  const LinearProgressIndicator(
                    color: AppColors.neonBlue,
                    backgroundColor: AppColors.mutedBackground,
                  ),
                  SizedBox(height: 16.h),
                ],
                TournamentDisputesAlertBanner(
                  disputedCount: disputedCount,
                  player1Name: state.disputedMatches.firstOrNull?.player1Name ?? 'P1',
                  player2Name: state.disputedMatches.firstOrNull?.player2Name ?? 'P2',
                  onResolve: () => _tabController.animateTo(3),
                ),
                if (disputedCount > 0) SizedBox(height: 16.h),
                TournamentSelectorBar(
                  tournaments: state.tournaments,
                  selected: selected,
                  onSelect: _onSelectTournament,
                  onManagePrizes: () {
                    if (selected != null) _openPrizesDialog(selected);
                  },
                  onPublish: () {
                    if (selected != null) {
                      context.read<TournamentCubit>().publishTournament(selected.id);
                    }
                  },
                  onDeleteDraft: () {
                    if (selected != null) _confirmDeleteDraft(selected);
                  },
                  onCancel: () {
                    if (selected != null) _confirmCancel(selected);
                  },
                  onAwardPrizes: () {
                    if (selected != null) {
                      context.read<TournamentCubit>().awardPrizes(selected.id);
                    }
                  },
                ),
                if (state.tournaments.isNotEmpty) SizedBox(height: 20.h),
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
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                '$disputedCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(text: '${AppStrings.auditTrail} (${state.auditLogs.length})'),
                  ],
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  height: 600.h,
                  child: TournamentTabBarView(
                    tabController: _tabController,
                    state: state,
                    selected: selected,
                    onManagePrizes: _openPrizesDialog,
                    onEdit: _openEditDialog,
                    onDelete: _confirmDelete,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
