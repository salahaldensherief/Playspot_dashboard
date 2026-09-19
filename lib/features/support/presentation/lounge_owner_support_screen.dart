import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../art_core/theme/app_colors.dart';
import '../../../art_core/widgets/app_button.dart';
import '../../../art_core/widgets/section_container.dart';
import '../../../art_core/widgets/status_badge.dart';
import 'support_cubit.dart';
import 'support_state.dart';

class LoungeOwnerSupportScreen extends StatefulWidget {
  const LoungeOwnerSupportScreen({super.key});

  @override
  State<LoungeOwnerSupportScreen> createState() => _LoungeOwnerSupportScreenState();
}

class _LoungeOwnerSupportScreenState extends State<LoungeOwnerSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedIssueType = 'payment';
  final _messageController = TextEditingController();

  final List<Map<String, String>> _issueTypes = [
    {'key': 'payment', 'label': 'تسويات ومستحقات مادية (Payouts)'},
    {'key': 'technical', 'label': 'مشاكل تقنية باللوحة أو الستايشن'},
    {'key': 'booking', 'label': 'حجوزات أو رومات'},
    {'key': 'lounge', 'label': 'بيانات وإعدادات الصالة'},
    {'key': 'other', 'label': 'عام / أخرى'},
  ];

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SupportCubit>();
    cubit.loadAppSettings();
    cubit.loadFaqs();
    cubit.loadTickets();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'غير محدد';
    return DateFormat('yyyy/MM/dd - hh:mm a').format(dt);
  }

  Widget _buildTicketStatusBadge(String status) {
    switch (status) {
      case 'new':
        return StatusBadge.warning('جديدة (قيد الانتظار)');
      case 'in_progress':
        return StatusBadge.info('جاري المعالجة');
      case 'resolved':
        return StatusBadge.success('تم الحل والتجاوب');
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
          _messageController.clear();
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
        final settings = state.settings;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.headset_mic_outlined, color: AppColors.neonBlue, size: 28.r),
                    SizedBox(width: 12.w),
                    Text(
                      'مركز الدعم الفني والمساعدة',
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
                  'تواصل مع فريق إدارة منصة بلاي سبوت لتقديم البلاغات، طلب المساعدة، وتتبع حالة تذاكر الدعم الخاصة بك',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Contact Details & Vodafone Cash
                    Expanded(
                      flex: 4,
                      child: SectionContainer(
                        title: 'وسائل التواصل المباشر',
                        children: [
                          _buildContactTile(
                            icon: Icons.chat_bubble_outline,
                            color: AppColors.success,
                            title: 'واتساب الدعم الفني',
                            value: settings?.whatsappPhone.isNotEmpty == true
                                ? settings!.whatsappPhone
                                : 'غير متوفر حالياً',
                          ),
                          SizedBox(height: 12.h),
                          _buildContactTile(
                            icon: Icons.phone_outlined,
                            color: AppColors.neonBlue,
                            title: 'الهاتف المباشر',
                            value: settings?.supportPhone.isNotEmpty == true
                                ? settings!.supportPhone
                                : 'غير متوفر حالياً',
                          ),
                          SizedBox(height: 12.h),
                          _buildContactTile(
                            icon: Icons.email_outlined,
                            color: AppColors.neonPurple,
                            title: 'البريد الإلكتروني',
                            value: settings?.supportEmail.isNotEmpty == true
                                ? settings!.supportEmail
                                : 'support@playspot.app',
                          ),
                          SizedBox(height: 12.h),
                          _buildContactTile(
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppColors.warning,
                            title: 'محفظة فودافون كاش الرسمية',
                            value: settings?.vodafoneCashNumber.isNotEmpty == true
                                ? settings!.vodafoneCashNumber
                                : 'غير متوفر حالياً',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 24.w),
                    // Card 2: Create New Ticket
                    Expanded(
                      flex: 5,
                      child: SectionContainer(
                        title: 'تقديم تذكرة دعم / بلاغ جديد',
                        children: [
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('نوع الشكوى / الاستفسار',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
                                SizedBox(height: 6.h),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.scaffoldBackground,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(color: AppColors.borderDefault),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedIssueType,
                                      dropdownColor: AppColors.cardBackground,
                                      isExpanded: true,
                                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                                      items: _issueTypes.map((i) {
                                        return DropdownMenuItem<String>(
                                          value: i['key'],
                                          child: Text(i['label']!),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedIssueType = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Text('تفاصيل المشكلة / الرسالة',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
                                SizedBox(height: 6.h),
                                TextFormField(
                                  controller: _messageController,
                                  maxLines: 4,
                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                                  decoration: InputDecoration(
                                    hintText: 'اكتب تفاصيل استفسارك أو مشكلتك بالتفصيل ليتم إفادتك فوراً...',
                                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
                                    filled: true,
                                    fillColor: AppColors.scaffoldBackground,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'يرجى كتابة نص الرسالة أو الشكوى';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16.h),
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: AppButton(
                                    text: 'إرسال التذكرة',
                                    variant: AppButtonVariant.gradient,
                                    icon: Icons.send_rounded,
                                    isLoading: state.actionStatus == SupportStatus.loading,
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<SupportCubit>().createTicket(
                                              issueType: _selectedIssueType,
                                              message: _messageController.text.trim(),
                                            );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                // Card 3: My Support Tickets
                SectionContainer(
                  title: 'تذاكري واستفساراتي السابقة (${state.tickets.length})',
                  children: [
                    if (state.status == SupportStatus.loading && state.tickets.isEmpty)
                      const Center(child: CircularProgressIndicator(color: AppColors.neonBlue))
                    else if (state.tickets.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.r),
                          child: Text(
                            'لم تقم بتقديم أي تذاكر دعم سابقة حتى الآن.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                          ),
                        ),
                      )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Table(
                          border: TableBorder.all(color: AppColors.borderDefault, width: 1),
                          columnWidths: const {
                            0: FlexColumnWidth(1.2),
                            1: FlexColumnWidth(2.5),
                            2: FlexColumnWidth(1.4),
                            3: FlexColumnWidth(1.4),
                            4: FlexColumnWidth(2.0),
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(color: AppColors.scaffoldBackground),
                              children: [
                                _buildHeaderCell('نوع المشكلة'),
                                _buildHeaderCell('تفاصيل الرسالة'),
                                _buildHeaderCell('تاريخ الإرسال'),
                                _buildHeaderCell('الحالة'),
                                _buildHeaderCell('رد الآدمن والملاحظات'),
                              ],
                            ),
                            ...state.tickets.map((ticket) {
                              return TableRow(
                                children: [
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
                                  _buildDataCell(
                                    ticket.adminNotes?.isNotEmpty == true
                                        ? ticket.adminNotes!
                                        : 'بانتظار مراجعة الإدارة',
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 24.h),
                // Card 4: FAQs
                if (state.faqs.isNotEmpty)
                  SectionContainer(
                    title: 'الأسئلة الشائعة وتوجيهات الصالات (FAQ)',
                    children: [
                      ...state.faqs.map((faq) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBackground,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: AppColors.borderDefault),
                          ),
                          child: ExpansionTile(
                            iconColor: AppColors.neonBlue,
                            collapsedIconColor: AppColors.textSecondary,
                            title: Text(
                              faq.questionAr,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16.r),
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    faq.answerAr,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13.sp,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
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
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Column(
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
        ],
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
