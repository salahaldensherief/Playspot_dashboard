import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../domain/entities/support_ticket_entity.dart';

class TicketDetailsDialog extends StatefulWidget {
  final SupportTicketEntity ticket;
  final Function(String newStatus, String? notes) onStatusChanged;

  const TicketDetailsDialog({
    super.key,
    required this.ticket,
    required this.onStatusChanged,
  });

  @override
  State<TicketDetailsDialog> createState() => _TicketDetailsDialogState();
}

class _TicketDetailsDialogState extends State<TicketDetailsDialog> {
  late String _selectedStatus;
  late TextEditingController _notesController;

  List<Map<String, String>> get _statusOptions => [
    {'key': 'new', 'label': AppStrings.ticketStatusNew},
    {'key': 'in_progress', 'label': AppStrings.ticketStatusInProgress},
    {'key': 'resolved', 'label': AppStrings.ticketStatusResolved},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.ticket.status;
    _notesController = TextEditingController(text: widget.ticket.adminNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return AppStrings.unspecified;
    return DateFormat('yyyy/MM/dd - hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.confirmation_number_outlined, color: AppColors.neonBlue, size: 24.r),
              SizedBox(width: 8.w),
              Text(
                AppStrings.complaintDetails,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 550.w,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow(AppStrings.fullName, widget.ticket.userName, Icons.person_outline),
              _buildInfoRow(AppStrings.phoneNumber, widget.ticket.userPhone, Icons.phone_outlined),
              _buildInfoRow(AppStrings.issueType, widget.ticket.issueType, Icons.category_outlined),
              _buildInfoRow(AppStrings.sentDate, _formatDate(widget.ticket.createdAt), Icons.calendar_today_outlined),
              if (widget.ticket.resolvedAt != null)
                _buildInfoRow(AppStrings.resolvedDate, _formatDate(widget.ticket.resolvedAt), Icons.check_circle_outline),
              SizedBox(height: 16.h),
              const Divider(color: AppColors.borderDefault),
              SizedBox(height: 12.h),
              Text(AppStrings.ticketMessageText, style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold, fontSize: 14.sp)),
              SizedBox(height: 6.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.mutedBackground,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Text(
                  widget.ticket.message,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, height: 1.4),
                ),
              ),
              SizedBox(height: 20.h),
              const Divider(color: AppColors.borderDefault),
              SizedBox(height: 12.h),
              Text(AppStrings.updateTicketStatus, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp)),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: AppColors.mutedBackground,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    dropdownColor: AppColors.cardBackground,
                    isExpanded: true,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                    items: _statusOptions.map((s) {
                      return DropdownMenuItem<String>(
                        value: s['key'],
                        child: Text(s['label']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedStatus = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(AppStrings.adminNotes, style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
              SizedBox(height: 6.h),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: AppStrings.adminNotesHint,
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
                  filled: true,
                  fillColor: AppColors.mutedBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.cancel, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        AppButton(
          text: AppStrings.updateStatus,
          variant: AppButtonVariant.gradient,
          onPressed: () {
            widget.onStatusChanged(_selectedStatus, _notesController.text.trim());
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 16.r),
          SizedBox(width: 8.w),
          Text('$label:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
          SizedBox(width: 4.w),
          Text(value, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.sp)),
        ],
      ),
    );
  }
}
