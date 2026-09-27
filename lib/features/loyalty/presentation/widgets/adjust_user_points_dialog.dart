import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../../art_core/widgets/app_text_field.dart';
import '../../../../art_core/widgets/custom_dropdown.dart';
import '../../../../core/di/di.dart';

class AdjustUserPointsDialog extends StatefulWidget {
  final Function(String userId, int pointsDelta, String reason) onAdjust;

  const AdjustUserPointsDialog({
    super.key,
    required this.onAdjust,
  });

  @override
  State<AdjustUserPointsDialog> createState() => _AdjustUserPointsDialogState();
}

class _AdjustUserPointsDialogState extends State<AdjustUserPointsDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pointsDeltaController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _pointsDeltaController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      final supabase = sl<SupabaseClient>();
      final response = await supabase
          .from('profiles')
          .select('id, full_name, email, points_balance')
          .order('full_name')
          .limit(100);

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
          _isLoadingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  void _submit() {
    if (_selectedUserId == null || _selectedUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.selectUser), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final delta = int.tryParse(_pointsDeltaController.text.trim()) ?? 0;
      final reason = _reasonController.text.trim();

      widget.onAdjust(_selectedUserId!, delta, reason);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.pointsUpdatedSuccess), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? selectedUser;
    for (final u in _users) {
      if (u['id']?.toString() == _selectedUserId) {
        selectedUser = u;
        break;
      }
    }

    final currentPoints = selectedUser != null ? ((selectedUser['points_balance'] as num?)?.toInt() ?? 0) : 0;
    final userIds = _users.map((u) => u['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 480.w,
        padding: EdgeInsets.all(24.r),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_attributes_rounded, color: AppColors.neonBlue, size: 24.r),
                      SizedBox(width: 8.w),
                      AppText.subHeading(AppStrings.adjustUserPoints, fontSize: 20.sp),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderDefault, height: 24),
              AppText.body(AppStrings.superAdminOnlyPoints, fontSize: 12.sp, color: AppColors.warning),
              SizedBox(height: 16.h),

              // User Selector
              if (_isLoadingUsers)
                const Center(child: CircularProgressIndicator(color: AppColors.neonBlue))
              else
                CustomDropdown<String>(
                  label: AppStrings.selectUser,
                  value: _selectedUserId,
                  items: userIds,
                  itemLabel: (id) {
                    for (final u in _users) {
                      if (u['id']?.toString() == id) {
                        final name = u['full_name']?.toString() ?? 'User';
                        final email = u['email']?.toString() ?? '';
                        final pts = (u['points_balance'] as num?)?.toInt() ?? 0;
                        return '$name ($email) - $pts ${AppStrings.pointsUnit}';
                      }
                    }
                    return id;
                  },
                  onChanged: (val) {
                    setState(() => _selectedUserId = val);
                  },
                ),

              if (_selectedUserId != null && _selectedUserId!.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.neonBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.body(AppStrings.pointsBalance, fontSize: 12.sp, color: AppColors.textSecondary),
                      AppText.body('$currentPoints ${AppStrings.pointsUnit}', fontWeight: FontWeight.bold, color: AppColors.neonBlue),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 16.h),

              // Points Delta (+ or -)
              AppTextField(
                label: AppStrings.pointsDelta,
                controller: _pointsDeltaController,
                hintText: AppStrings.pointsDeltaHint,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return AppStrings.fieldRequired;
                  if (int.tryParse(val.trim()) == null) return AppStrings.invalidNumber;
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Reason
              AppTextField(
                label: AppStrings.reasonOrNote,
                controller: _reasonController,
                hintText: AppStrings.reasonHint,
                maxLines: 2,
                validator: (val) => val == null || val.trim().isEmpty ? AppStrings.fieldRequired : null,
              ),
              SizedBox(height: 24.h),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: AppStrings.cancel,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 12.w),
                  AppButton(
                    text: AppStrings.saveChanges,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
