import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_adaptive_page_header.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import '../domain/entities/app_settings_entity.dart';
import '../domain/entities/support_ticket_entity.dart';
import 'support_cubit.dart';
import 'support_state.dart';

class LoungeOwnerSupportScreen extends StatefulWidget {
  const LoungeOwnerSupportScreen({super.key});

  @override
  State<LoungeOwnerSupportScreen> createState() => _LoungeOwnerSupportScreenState();
}

class _LoungeOwnerSupportScreenState extends State<LoungeOwnerSupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SupportCubit>().loadAppSettings();
        context.read<SupportCubit>().loadTickets();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: AppStrings.supportAndHelp,
      activeRoute: 'Support',
      child: BlocBuilder<SupportCubit, SupportState>(
        builder: (context, state) {
          final isLoading = state.status == SupportStatus.loading;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAdaptivePageHeader(
                title: AppStrings.supportCenter,
                subtitle: AppStrings.supportCenterSubtitle,
                primaryAction: AppButton(
                  text: AppStrings.refresh,
                  icon: Icons.refresh,
                  variant: AppButtonVariant.outlined,
                  onPressed: () {
                    context.read<SupportCubit>().loadAppSettings();
                    context.read<SupportCubit>().loadTickets();
                  },
                ),
              ),
              SizedBox(height: 24.h),

              // Direct Support Channels
              _buildSupportSettingsCard(state.settings),
              SizedBox(height: 24.h),

              // User's Support Tickets
              AppText.heading(AppStrings.supportTickets, fontSize: 18.sp),
              SizedBox(height: 12.h),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppColors.neonBlue),
                  ),
                )
              else if (state.tickets.isEmpty)
                _buildEmptyTicketsCard()
              else
                _buildTicketsTable(state.tickets),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSupportSettingsCard(AppSettingsEntity? settings) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.headset_mic_outlined, color: AppColors.neonBlue, size: 24.r),
              SizedBox(width: 8.w),
              AppText.heading(AppStrings.directSupportChannels, fontSize: 18.sp),
            ],
          ),
          SizedBox(height: 16.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final tiles = [
                _buildContactTile(
                  icon: Icons.chat_bubble_outline,
                  color: AppColors.success,
                  title: AppStrings.whatsappSupport,
                  value: settings?.whatsappPhone ?? '+201000000000',
                ),
                _buildContactTile(
                  icon: Icons.phone_outlined,
                  color: AppColors.neonBlue,
                  title: AppStrings.phone,
                  value: settings?.supportPhone ?? '19000',
                ),
                _buildContactTile(
                  icon: Icons.email_outlined,
                  color: AppColors.warning,
                  title: AppStrings.email,
                  value: settings?.supportEmail ?? 'support@playspot.app',
                ),
                _buildContactTile(
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.neonGreen,
                  title: AppStrings.vodafoneCash,
                  value: settings?.vodafoneCashNumber ?? '01000000000',
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: tiles
                      .map((tile) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: tile,
                          ))
                      .toList(),
                );
              }

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 3.2,
                children: tiles,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTicketsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, color: AppColors.textSecondary, size: 48.r),
          SizedBox(height: 12.h),
          AppText.body(AppStrings.noTicketsFound, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildTicketsTable(List<SupportTicketEntity> tickets) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.mutedBackground),
            columns: [
              DataColumn(label: _buildHeaderCell(AppStrings.nameAndDetails)),
              DataColumn(label: _buildHeaderCell(AppStrings.issueType)),
              DataColumn(label: _buildHeaderCell(AppStrings.status)),
              DataColumn(label: _buildHeaderCell(AppStrings.date)),
            ],
            rows: tickets.map((ticket) {
              return DataRow(
                cells: [
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ticket.userName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          ticket.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(ticket.issueType, style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp))),
                  DataCell(_getStatusBadge(ticket.status)),
                  DataCell(
                    Text(
                      ticket.createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(ticket.createdAt!) : 'N/A',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
                SizedBox(height: 2.h),
                SelectableText(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: EdgeInsets.all(12.r),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 13.sp,
        ),
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'new':
        return StatusBadge.info(AppStrings.open);
      case 'in_progress':
        return StatusBadge.warning(AppStrings.inProgress);
      case 'resolved':
      case 'closed':
        return StatusBadge.success(AppStrings.ticketStatusResolved);
      default:
        return StatusBadge.secondary(status);
    }
  }
}
