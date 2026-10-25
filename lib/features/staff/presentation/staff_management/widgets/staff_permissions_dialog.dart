import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/features/permissions/domain/entities/permission_item_entity.dart';
import 'package:play_spot_dashboard/features/permissions/domain/repositories/permissions_repository.dart';
import 'package:play_spot_dashboard/features/staff/domain/entities/staff_entity.dart';

class StaffPermissionsDialog extends StatefulWidget {
  final StaffEntity staff;
  final PermissionsRepository repository;

  const StaffPermissionsDialog({
    super.key,
    required this.staff,
    required this.repository,
  });

  @override
  State<StaffPermissionsDialog> createState() => _StaffPermissionsDialogState();
}

class _StaffPermissionsDialogState extends State<StaffPermissionsDialog> {
  List<PermissionItemEntity> _permissions = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await widget.repository.getStaffPermissions(
      widget.staff.id,
      loungeId: widget.staff.loungeId,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _loading = false;
      }),
      (permissions) => setState(() {
        _permissions = permissions;
        _error = null;
        _loading = false;
      }),
    );
  }

  Future<void> _set(PermissionItemEntity permission, bool enabled) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.repository.setStaffPermission(
      loungeId: widget.staff.loungeId,
      staffId: widget.staff.id,
      permissionKey: permission.key,
      isEnabled: enabled,
    );
    if (!mounted) return;
    await result.fold(
      (failure) async => setState(() => _error = failure.message),
      (_) => _load(),
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return AppDialog(
      title: 'staff_custom_permissions'.tr(),
      icon: Icons.admin_panel_settings_outlined,
      width: 620,
      child: SizedBox(
        height: 500,
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_permissions.isEmpty)
              Expanded(
                child: Center(child: Text('staff_permissions_empty'.tr())),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _permissions.length,
                  itemBuilder: (context, index) {
                    final permission = _permissions[index];
                    final label = isArabic
                        ? permission.nameAr
                        : permission.nameEn;
                    return SwitchListTile(
                      title: Text(label.isEmpty ? permission.key : label),
                      subtitle: Text(
                        isArabic
                            ? permission.descriptionAr
                            : permission.descriptionEn,
                      ),
                      value: permission.isEnabled,
                      onChanged: _saving
                          ? null
                          : (value) => _set(permission, value),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
