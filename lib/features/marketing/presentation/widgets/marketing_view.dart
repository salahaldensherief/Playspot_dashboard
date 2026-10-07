import 'package:easy_localization/easy_localization.dart';
import '../marketing_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_adaptive_page_header.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import '../../domain/entities/promo_entity.dart';
import '../cubit/marketing_cubit.dart';
import '../cubit/marketing_state.dart';
import 'promo_dialog.dart';
import 'notification_dialog.dart';
import 'promo_card.dart';

class MarketingView extends StatefulWidget {
  const MarketingView({super.key});

  @override
  State<MarketingView> createState() => _MarketingViewState();
}

class _MarketingViewState extends State<MarketingView> {
  String _selectedFilterStatus = 'All'; // All, Active, Expired, Archived
  String _selectedFilterTag = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<LoginCubit>().state.user;
      final loungeId = user?.loungeId;
      context.read<MarketingCubit>().loadPromotions(loungeId: loungeId);
      if (loungeId != null && loungeId.isNotEmpty) {
        context.read<RoomCubit>().watchRooms(loungeId);
      }
    });
  }

  void _reloadPromotions() {
    final user = context.read<LoginCubit>().state.user;
    context.read<MarketingCubit>().loadPromotions(loungeId: user?.loungeId);
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final user = context.read<LoginCubit>().state.user;
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    final marketingCubit = context.read<MarketingCubit>();

    return BlocListener<MarketingCubit, MarketingState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.status == MarketingStatus.actionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionMessageKey.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state.status == MarketingStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(marketingMessage(state.errorMessage)),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section (Adaptive)
            AppAdaptivePageHeader(
              title: AppStrings.marketing,
              subtitle: AppStrings.promotionsMarketing,
              secondaryAction: isSuperAdmin
                  ? AppButton(
                      text: AppStrings.newNotification,
                      onPressed: () =>
                          _showNotificationDialog(context, marketingCubit),
                      icon: Icons.notifications_active_outlined,
                      variant: AppButtonVariant.outlined,
                    )
                  : null,
              primaryAction: AppButton(
                text: AppStrings.createPromotion,
                onPressed: () => _showEditPromoDialog(
                  context,
                  marketingCubit,
                  PromoEntity(
                    id: '',
                    titleAr: '',
                    titleEn: '',
                    tagAr: '',
                    tagEn: '',
                    hexColors: const [],
                    iconKey: 'Flash',
                    loungeId: user?.loungeId,
                  ),
                ),
                icon: Icons.add,
              ),
            ),
            SizedBox(height: 24.h),

            // Main Promotions Dashboard Content
            Expanded(child: _buildPromotionsContent(marketingCubit)),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsContent(MarketingCubit cubit) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId;

    return BlocBuilder<MarketingCubit, MarketingState>(
      buildWhen: (previous, current) =>
          previous.promotions != current.promotions ||
          previous.status != current.status,
      builder: (context, state) {
        if (state.status == MarketingStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.neonBlue),
          );
        }
        if (state.status == MarketingStatus.failure &&
            state.promotions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  marketingMessage(state.errorMessage),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                SizedBox(height: 12.h),
                AppButton(
                  text: AppStrings.refresh,
                  icon: Icons.refresh,
                  onPressed: _reloadPromotions,
                ),
              ],
            ),
          );
        }

        final now = DateTime.now();
        var promos = state.promotions;

        // Filter by Status (Active / Expired)
        if (_selectedFilterStatus == 'Active') {
          promos = promos
              .where(
                (p) =>
                    p.isActive &&
                    (p.expiresAt == null || p.expiresAt!.isAfter(now)),
              )
              .toList();
        } else if (_selectedFilterStatus == 'Expired') {
          promos = promos
              .where(
                (p) =>
                    p.isActive &&
                    p.expiresAt != null &&
                    p.expiresAt!.isBefore(now),
              )
              .toList();
        } else if (_selectedFilterStatus == 'Archived') {
          promos = promos.where((p) => !p.isActive).toList();
        }

        // Filter by Tag
        if (_selectedFilterTag != 'All') {
          promos = promos
              .where(
                (p) =>
                    p.tag == _selectedFilterTag ||
                    p.tagAr == _selectedFilterTag,
              )
              .toList();
        }

        final tags = [
          'All',
          ...state.promotions
              .map((p) => p.tag ?? p.tagAr)
              .where((t) => t.isNotEmpty)
              .toSet(),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Tag Filter Chips Row
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip(AppStrings.all, 'All'),
                      SizedBox(width: 8.w),
                      _buildStatusChip(AppStrings.active, 'Active'),
                      SizedBox(width: 8.w),
                      _buildStatusChip(AppStrings.timeExpired, 'Expired'),
                      SizedBox(width: 8.w),
                      _buildStatusChip(
                        AppStrings.archivedPromotions,
                        'Archived',
                      ),
                    ],
                  ),
                ),
                if (tags.length > 1) ...[
                  SizedBox(height: 6.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: tags.map((tag) {
                        return Padding(
                          padding: EdgeInsetsDirectional.only(start: 6.w),
                          child: FilterChip(
                            label: Text(tag == 'All' ? AppStrings.all : tag),
                            selected: _selectedFilterTag == tag,
                            onSelected: (selected) {
                              setState(() => _selectedFilterTag = tag);
                            },
                            selectedColor: AppColors.neonBlue.withAlpha(51),
                            checkmarkColor: AppColors.neonBlue,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 20.h),

            // Grid or Empty State
            if (promos.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 64.r,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        AppStrings.noPromotions,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      AppButton(
                        text: AppStrings.createPromotion,
                        onPressed: () => _showEditPromoDialog(
                          context,
                          cubit,
                          PromoEntity(
                            id: '',
                            titleAr: '',
                            titleEn: '',
                            tagAr: '',
                            tagEn: '',
                            hexColors: const [],
                            iconKey: 'Flash',
                            loungeId: loungeId,
                          ),
                        ),
                        icon: Icons.add,
                        height: 40.h,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380.w,
                    mainAxisExtent: 230.h,
                    crossAxisSpacing: 20.w,
                    mainAxisSpacing: 20.h,
                  ),
                  itemCount: promos.length,
                  itemBuilder: (context, index) {
                    final promo = promos[index];
                    return PromoCard(
                      promo: promo,
                      onEdit: promo.isActive
                          ? () => _showEditPromoDialog(context, cubit, promo)
                          : null,
                      onDelete: promo.isActive
                          ? () => _confirmDelete(
                              context,
                              cubit,
                              promo,
                              loungeId: loungeId,
                            )
                          : null,
                      onReshare: () => cubit.resharePromotion(
                        promo.id,
                        loungeId: loungeId,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(String label, String statusKey) {
    final isSelected = _selectedFilterStatus == statusKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilterStatus = statusKey);
        }
      },
      selectedColor: AppColors.neonBlue.withAlpha(51),
      backgroundColor: AppColors.mutedBackground,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  void _showEditPromoDialog(
    BuildContext context,
    MarketingCubit cubit,
    PromoEntity promo,
  ) {
    final roomCubit = context.read<RoomCubit>();
    showDialog(
      context: context,
      builder: (diagContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: roomCubit),
          BlocProvider.value(value: cubit),
        ],
        child: PromoDialog(promo: promo, onSave: cubit.createPromotion),
      ),
    );
  }

  void _showNotificationDialog(BuildContext context, MarketingCubit cubit) {
    showDialog(
      context: context,
      builder: (diagContext) =>
          NotificationDialog(onSend: (n) => cubit.sendNotification(n)),
    );
  }

  void _confirmDelete(
    BuildContext context,
    MarketingCubit cubit,
    PromoEntity promo, {
    String? loungeId,
  }) {
    final title = promo.titleAr.isNotEmpty ? promo.titleAr : promo.titleEn;
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          AppStrings.archivePromotion,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '${AppStrings.archivePromotion}: "$title"؟',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.outlined,
            onPressed: () => Navigator.pop(diagContext),
          ),
          AppButton(
            text: AppStrings.archivePromotion,
            variant: AppButtonVariant.danger,
            onPressed: () {
              cubit.deletePromotion(promo.id, loungeId: loungeId);
              Navigator.pop(diagContext);
            },
          ),
        ],
      ),
    );
  }
}
