import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../../domain/entities/promo_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../cubit/marketing_cubit.dart';
import '../cubit/marketing_state.dart';
import 'promo_form_section.dart';
import 'design_style_section.dart';
import 'promo_dialog.dart';
import 'notification_dialog.dart';

class MarketingView extends StatefulWidget {
  const MarketingView({super.key});

  @override
  State<MarketingView> createState() => _MarketingViewState();
}

class _MarketingViewState extends State<MarketingView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  final List<List<Color>> _colorTemplates = [
    [AppColors.neonPurple, AppColors.neonBlue],
    [Colors.orange, Colors.red],
    [Colors.green, Colors.teal],
    [Colors.blue, Colors.indigo],
  ];

  int _selectedTemplate = 0;
  String _selectedIcon = 'Flash';
  String _selectedDeepLink = 'Specific Room';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final isSuperAdmin = user?.role.name == 'superAdmin';
    final marketingCubit = context.read<MarketingCubit>();

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.marketing,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              if (isSuperAdmin)
                Row(
                  children: [
                    AppButton(
                      text: 'New Notification',
                      onPressed: () => _showNotificationDialog(context, marketingCubit),
                      icon: Icons.notifications_active_outlined,
                      variant: AppButtonVariant.outlined,
                    ),
                    SizedBox(width: 16.w),
                    AppButton(
                      text: AppStrings.createGlobalPromo,
                      onPressed: () => _showEditPromoDialog(context, marketingCubit, const PromoEntity(id: '', titleAr: '', titleEn: '', tagAr: '', tagEn: '', hexColors: [], iconKey: '')),
                      icon: Icons.add,
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 32.h),
          if (isSuperAdmin) ...[
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.neonBlue,
              indicatorColor: AppColors.neonBlue,
              tabs: const [
                Tab(text: 'Promotions'),
                Tab(text: 'Notifications History'),
              ],
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPromotionsList(marketingCubit),
                  _buildNotificationsList(marketingCubit),
                ],
              ),
            ),
          ] else 
            Expanded(child: SingleChildScrollView(child: _buildLoungeAdminForm())),
        ],
      ),
    );
  }

  Widget _buildLoungeAdminForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PromoFormSection(
            selectedDeepLink: _selectedDeepLink,
            onDeepLinkChanged: (v) => setState(() => _selectedDeepLink = v!),
          ),
          SizedBox(height: 32.h),
          DesignStyleSection(
            colorTemplates: _colorTemplates,
            selectedTemplate: _selectedTemplate,
            onTemplateSelected: (index) => setState(() => _selectedTemplate = index),
            selectedIcon: _selectedIcon,
            onIconChanged: (v) => setState(() => _selectedIcon = v!),
          ),
          SizedBox(height: 40.h),
          AppButton(
            text: AppStrings.createPromotion,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Save logic
              }
            },
            width: 250.w,
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsList(MarketingCubit cubit) {
    return BlocBuilder<MarketingCubit, MarketingState>(
      builder: (context, state) {
        if (state.status == MarketingStatus.loading) {
           return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
        }
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.promotions.isEmpty)
                const Center(child: Text('No promotions found', style: TextStyle(color: AppColors.textSecondary)))
              else
                DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.mutedBackground),
                  columns: [
                    DataColumn(label: Text(AppStrings.promoTitleEn)),
                    DataColumn(label: Text(AppStrings.tagEn)),
                    DataColumn(label: Text(AppStrings.userLabel)),
                    DataColumn(label: Text(AppStrings.status)),
                    DataColumn(label: Text(AppStrings.actions)),
                  ],
                  rows: state.promotions.map((p) => _buildPromoRow(context, cubit, p)).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationsList(MarketingCubit cubit) {
    return BlocBuilder<MarketingCubit, MarketingState>(
      builder: (context, state) {
        if (state.status == MarketingStatus.loading) return const Center(child: CircularProgressIndicator());
        if (state.notifications.isEmpty) return const Center(child: Text('No notification history', style: TextStyle(color: AppColors.textSecondary)));

        return ListView.separated(
          itemCount: state.notifications.length,
          separatorBuilder: (_, __) => Divider(color: AppColors.borderDefault),
          itemBuilder: (context, index) {
            final n = state.notifications[index];
            return ListTile(
              leading: Icon(_getNotifyIcon(n.type), color: AppColors.neonBlue),
              title: Text(n.titleEn, style: const TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(n.bodyEn, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
              trailing: Text(DateFormat('yyyy-MM-dd HH:mm').format(n.createdAt), style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp)),
            );
          },
        );
      },
    );
  }

  IconData _getNotifyIcon(NotificationType type) {
    switch (type) {
      case NotificationType.offer: return Icons.local_offer_outlined;
      case NotificationType.booking: return Icons.event_available;
      case NotificationType.loyalty: return Icons.card_giftcard;
      default: return Icons.info_outline;
    }
  }

  DataRow _buildPromoRow(BuildContext context, MarketingCubit cubit, PromoEntity promo) {
    return DataRow(cells: [
      DataCell(Text(promo.titleEn, style: const TextStyle(color: AppColors.textPrimary))),
      DataCell(Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(color: AppColors.neonBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(4.r)),
        child: Text(promo.tagEn, style: const TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold)),
      )),
      DataCell(Text(promo.deepLink ?? 'Global', style: const TextStyle(color: AppColors.textSecondary))),
      DataCell(Text(AppStrings.active, style: const TextStyle(color: AppColors.success))),
      DataCell(Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20), 
            onPressed: () => _showEditPromoDialog(context, cubit, promo),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20), 
            onPressed: () => _confirmDelete(context, cubit, promo),
          ),
        ],
      )),
    ]);
  }

  void _showEditPromoDialog(BuildContext context, MarketingCubit cubit, PromoEntity promo) {
    showDialog(
      context: context,
      builder: (diagContext) => PromoDialog(
        promo: promo,
        onSave: (updatedPromo) {
          cubit.createPromotion(updatedPromo);
        },
      ),
    );
  }

  void _showNotificationDialog(BuildContext context, MarketingCubit cubit) {
    showDialog(
      context: context,
      builder: (diagContext) => NotificationDialog(
        onSend: (n) => cubit.sendNotification(n),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MarketingCubit cubit, PromoEntity promo) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.deleteConfirmation, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${AppStrings.deleteWarning} "${promo.titleEn}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagContext), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              cubit.deletePromotion(promo.id);
              Navigator.pop(diagContext);
            }, 
            child: Text(AppStrings.delete, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
