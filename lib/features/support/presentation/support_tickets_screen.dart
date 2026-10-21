import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../art_core/app_strings.dart';
import '../../../art_core/theme/app_colors.dart';
import '../../../art_core/widgets/section_container.dart';
import '../../../art_core/widgets/status_badge.dart';
import '../domain/entities/support_ticket_entity.dart';
import 'support_cubit.dart';
import 'support_state.dart';
import 'widgets/ticket_details_dialog.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().loadTickets();
  }

  void _openTicketDetails(SupportTicketEntity ticket) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return TicketDetailsDialog(
          ticket: ticket,
          onStatusChanged: (newStatus, notes) {
            context.read<SupportCubit>().changeTicketStatus(
              ticketId: ticket.id,
              status: newStatus,
              adminNotes: notes,
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return AppStrings.unspecified;
    return DateFormat('yyyy/MM/dd').format(dt);
  }

  Widget _buildTicketStatusBadge(String status) {
    switch (status) {
      case 'new':
        return StatusBadge.warning(AppStrings.ticketStatusNew);
      case 'in_progress':
        return StatusBadge.info(AppStrings.ticketStatusInProgress);
      case 'resolved':
        return StatusBadge.success(AppStrings.ticketStatusResolved);
      default:
        return StatusBadge.neutral(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return BlocConsumer<SupportCubit, SupportState>(
      listenWhen: (prev, curr) =>
          prev.actionStatus != curr.actionStatus ||
          prev.successMessage != curr.successMessage ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.actionStatus == SupportStatus.success &&
            state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state.actionStatus == SupportStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      color: AppColors.neonBlue,
                      size: 28.r,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        AppStrings.supportTickets,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  AppStrings.supportTicketsSubtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                _buildFilters(state.activeTicketFilter),
                SizedBox(height: 24.h),
                if (state.status == SupportStatus.loading &&
                    state.tickets.isEmpty)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.neonBlue),
                  )
                else if (state.status == SupportStatus.failure &&
                    state.tickets.isEmpty)
                  SectionContainer(
                    title: AppStrings.complaintTicketsList,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.danger,
                              size: 48,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              state.errorMessage ?? AppStrings.actionFailed,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  context.read<SupportCubit>().loadTickets(),
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(AppStrings.retry),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else if (state.tickets.isEmpty)
                  SectionContainer(
                    title: AppStrings.complaintTicketsList,
                    children: [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.r),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                color: AppColors.textMuted,
                                size: 48.r,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                AppStrings.noTicketsInFilter,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SectionContainer(
                    title:
                        '${AppStrings.complaintsTable} (${state.tickets.length})',
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) =>
                            constraints.maxWidth < 1080
                            ? Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (final ticket in state.tickets)
                                    SizedBox(
                                      width: constraints.maxWidth >= 600
                                          ? (constraints.maxWidth - 12) / 2
                                          : constraints.maxWidth,
                                      child: _buildTicketCard(ticket),
                                    ),
                                ],
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: SizedBox(
                                    width: constraints.maxWidth > 1100
                                        ? constraints.maxWidth
                                        : 1100,
                                    child: Table(
                                      border: TableBorder.all(
                                        color: AppColors.borderDefault,
                                        width: 1,
                                      ),
                                      columnWidths: const {
                                        0: FlexColumnWidth(1.8),
                                        1: FlexColumnWidth(1.4),
                                        2: FlexColumnWidth(1.2),
                                        3: FlexColumnWidth(2.6),
                                        4: FlexColumnWidth(1.2),
                                        5: FlexColumnWidth(1.4),
                                        6: FlexColumnWidth(0.8),
                                      },
                                      children: [
                                        TableRow(
                                          decoration: const BoxDecoration(
                                            color: AppColors.scaffoldBackground,
                                          ),
                                          children: [
                                            _buildHeaderCell(
                                              AppStrings.fullName,
                                            ),
                                            _buildHeaderCell(
                                              AppStrings.phoneNumber,
                                            ),
                                            _buildHeaderCell(
                                              AppStrings.issueType,
                                            ),
                                            _buildHeaderCell(
                                              AppStrings.message,
                                            ),
                                            _buildHeaderCell(AppStrings.date),
                                            _buildHeaderCell(AppStrings.status),
                                            _buildHeaderCell(AppStrings.view),
                                          ],
                                        ),
                                        ...state.tickets.map((ticket) {
                                          return TableRow(
                                            children: [
                                              _buildDataCell(ticket.userName),
                                              _buildDataCell(ticket.userPhone),
                                              _buildDataCell(ticket.issueType),
                                              _buildDataCell(ticket.message),
                                              _buildDataCell(
                                                _formatDate(ticket.createdAt),
                                              ),
                                              TableCell(
                                                verticalAlignment:
                                                    TableCellVerticalAlignment
                                                        .middle,
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.r),
                                                  child:
                                                      _buildTicketStatusBadge(
                                                        ticket.status,
                                                      ),
                                                ),
                                              ),
                                              TableCell(
                                                verticalAlignment:
                                                    TableCellVerticalAlignment
                                                        .middle,
                                                child: IconButton(
                                                  tooltip: AppStrings.view,
                                                  icon: const Icon(
                                                    Icons.visibility_outlined,
                                                    color: AppColors.neonBlue,
                                                  ),
                                                  onPressed: () =>
                                                      _openTicketDetails(
                                                        ticket,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters(String activeFilter) {
    final filters = [
      ('all', AppStrings.allTickets),
      ('new', AppStrings.ticketStatusNew),
      ('in_progress', AppStrings.ticketStatusInProgress),
      ('resolved', AppStrings.ticketStatusResolved),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final chips = [
          for (final (key, label) in filters)
            _buildFilterChip(key, label, activeFilter),
        ];
        if (constraints.maxWidth < 720) {
          return Wrap(spacing: 8, runSpacing: 8, children: chips);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                chips[i],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTicketCard(SupportTicketEntity ticket) {
    return Material(
      color: AppColors.scaffoldBackground,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: () => _openTicketDetails(ticket),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderDefault),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.userName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _buildTicketStatusBadge(ticket.status),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                ticket.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 4.h,
                children: [
                  Text(
                    ticket.issueType,
                    style: const TextStyle(color: AppColors.neonBlue),
                  ),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                AppStrings.view,
                style: const TextStyle(
                  color: AppColors.neonBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String filterKey,
    String label,
    String currentFilter,
  ) {
    final isSelected = currentFilter == filterKey;
    return InkWell(
      onTap: () {
        context.read<SupportCubit>().loadTickets(statusFilter: filterKey);
      },
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonBlue : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.neonBlue : AppColors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: EdgeInsets.all(12.r),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.neonBlue,
          fontWeight: FontWeight.bold,
          fontSize: 13.sp,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Padding(
      padding: EdgeInsets.all(12.r),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
      ),
    );
  }
}
