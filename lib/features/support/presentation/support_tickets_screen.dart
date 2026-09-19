import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
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
    if (dt == null) return 'غير محدد';
    return DateFormat('yyyy/MM/dd').format(dt);
  }

  Widget _buildTicketStatusBadge(String status) {
    switch (status) {
      case 'new':
        return StatusBadge.warning('جديدة');
      case 'in_progress':
        return StatusBadge.info('جاري العمل عليها');
      case 'resolved':
        return StatusBadge.success('تم الحل');
      default:
        return StatusBadge.neutral(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SupportCubit, SupportState>(
      listenWhen: (prev, curr) =>
          prev.actionStatus != curr.actionStatus ||
          prev.successMessage != curr.successMessage ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.actionStatus == SupportStatus.success && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state.actionStatus == SupportStatus.failure && state.errorMessage != null) {
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
                    Icon(Icons.confirmation_number_outlined, color: AppColors.neonBlue, size: 28.r),
                    SizedBox(width: 12.w),
                    Text(
                      'إدارة تذاكر الشكاوى والدعم',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'استقبال ومتابعة وحل الشكاوى والاستفسارات المرسلة من مستخدمي التطبيق',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    _buildFilterChip('all', 'جميع التذاكر', state.activeTicketFilter),
                    SizedBox(width: 12.w),
                    _buildFilterChip('new', 'جديدة', state.activeTicketFilter),
                    SizedBox(width: 12.w),
                    _buildFilterChip('in_progress', 'جاري العمل عليها', state.activeTicketFilter),
                    SizedBox(width: 12.w),
                    _buildFilterChip('resolved', 'تم الحل', state.activeTicketFilter),
                  ],
                ),
                SizedBox(height: 24.h),
                if (state.status == SupportStatus.loading && state.tickets.isEmpty)
                  const Center(child: CircularProgressIndicator(color: AppColors.neonBlue))
                else if (state.tickets.isEmpty)
                  SectionContainer(
                    title: 'قائمة تذاكر الشكاوى',
                    children: [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.r),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined, color: AppColors.textMuted, size: 48.r),
                              SizedBox(height: 12.h),
                              Text(
                                'لا توجد تذاكر شكاوى في هذا الفلتر',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SectionContainer(
                    title: 'جدول الشكاوى والطلبات (${state.tickets.length})',
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Table(
                          border: TableBorder.all(color: AppColors.borderDefault, width: 1),
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
                              decoration: const BoxDecoration(color: AppColors.scaffoldBackground),
                              children: [
                                _buildHeaderCell('اسم المستخدم'),
                                _buildHeaderCell('رقم الهاتف'),
                                _buildHeaderCell('نوع المشكلة'),
                                _buildHeaderCell('الرسالة'),
                                _buildHeaderCell('التاريخ'),
                                _buildHeaderCell('الحالة'),
                                _buildHeaderCell('عرض'),
                              ],
                            ),
                            ...state.tickets.map((ticket) {
                              return TableRow(
                                children: [
                                  _buildDataCell(ticket.userName),
                                  _buildDataCell(ticket.userPhone),
                                  _buildDataCell(ticket.issueType),
                                  _buildDataCell(ticket.message),
                                  _buildDataCell(_formatDate(ticket.createdAt)),
                                  TableCell(
                                    verticalAlignment: TableCellVerticalAlignment.middle,
                                    child: Padding(
                                      padding: EdgeInsets.all(8.r),
                                      child: _buildTicketStatusBadge(ticket.status),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment: TableCellVerticalAlignment.middle,
                                    child: IconButton(
                                      icon: const Icon(Icons.visibility_outlined, color: AppColors.neonBlue),
                                      onPressed: () => _openTicketDetails(ticket),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
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

  Widget _buildFilterChip(String filterKey, String label, String currentFilter) {
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
          border: Border.all(color: isSelected ? AppColors.neonBlue : AppColors.borderDefault),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
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
        style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold, fontSize: 13.sp),
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
