import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../art_core/app_strings.dart';
import '../../../art_core/theme/app_colors.dart';
import '../../../art_core/widgets/app_adaptive_page_header.dart';
import '../../../art_core/widgets/app_button.dart';
import '../../../art_core/widgets/section_container.dart';
import '../../../art_core/widgets/status_badge.dart';
import '../domain/entities/faq_entity.dart';
import 'support_cubit.dart';
import 'support_state.dart';
import 'widgets/faq_dialog.dart';

class FaqManagementScreen extends StatefulWidget {
  const FaqManagementScreen({super.key});

  @override
  State<FaqManagementScreen> createState() => _FaqManagementScreenState();
}

class _FaqManagementScreenState extends State<FaqManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().loadFaqs();
  }

  void _openFaqDialog([FaqEntity? faq]) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return FaqDialog(
          faq: faq,
          onSave: (savedFaq) {
            context.read<SupportCubit>().saveFaq(savedFaq);
          },
        );
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(AppStrings.deleteConfirmation, style: const TextStyle(color: AppColors.textPrimary)),
          content: Text(AppStrings.deleteFaqConfirm, style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppStrings.cancel),
            ),
            AppButton(
              text: AppStrings.delete,
              variant: AppButtonVariant.danger,
              onPressed: () {
                context.read<SupportCubit>().removeFaq(id);
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );
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
                AppAdaptivePageHeader(
                  title: AppStrings.faqManagement,
                  subtitle: AppStrings.faqManagementSubtitle,
                  primaryAction: AppButton(
                    text: AppStrings.addFaq,
                    variant: AppButtonVariant.gradient,
                    icon: Icons.add,
                    onPressed: () => _openFaqDialog(),
                  ),
                ),
                SizedBox(height: 24.h),
                if (state.status == SupportStatus.loading && state.faqs.isEmpty)
                  const Center(child: CircularProgressIndicator(color: AppColors.neonBlue))
                else if (state.faqs.isEmpty)
                  SectionContainer(
                    title: AppStrings.faqTable,
                    children: [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.r),
                          child: Column(
                            children: [
                              Icon(Icons.help_outline, color: AppColors.textMuted, size: 48.r),
                              SizedBox(height: 12.h),
                              Text(
                                AppStrings.noDataFound,
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
                    title: '${AppStrings.faqTable} (${state.faqs.length})',
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Table(
                          border: TableBorder.all(color: AppColors.borderDefault, width: 1),
                          columnWidths: const {
                            0: FlexColumnWidth(3.0),
                            1: FlexColumnWidth(3.0),
                            2: FlexColumnWidth(1.0),
                            3: FlexColumnWidth(1.0),
                            4: FlexColumnWidth(1.0),
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(color: AppColors.scaffoldBackground),
                              children: [
                                _buildHeaderCell('السؤال (عربي)'),
                                _buildHeaderCell('Question (English)'),
                                _buildHeaderCell('الترتيب'),
                                _buildHeaderCell('الحالة'),
                                _buildHeaderCell('إجراءات'),
                              ],
                            ),
                            ...state.faqs.map((faq) {
                              return TableRow(
                                children: [
                                  _buildDataCell(faq.questionAr),
                                  _buildDataCell(faq.questionEn),
                                  _buildDataCell(faq.sortOrder.toString()),
                                  TableCell(
                                    verticalAlignment: TableCellVerticalAlignment.middle,
                                    child: Padding(
                                      padding: EdgeInsets.all(8.r),
                                      child: faq.isActive
                                          ? StatusBadge.success('مفعل')
                                          : StatusBadge.neutral('غير مفعل'),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment: TableCellVerticalAlignment.middle,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: AppColors.neonBlue),
                                          onPressed: () => _openFaqDialog(faq),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                          onPressed: () => _confirmDelete(faq.id),
                                        ),
                                      ],
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
        style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
      ),
    );
  }
}
