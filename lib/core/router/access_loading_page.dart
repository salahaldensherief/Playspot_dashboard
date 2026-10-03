import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/login/login_cubit.dart';
import '../../features/permissions/presentation/cubit/permissions_cubit.dart';
import '../../features/permissions/presentation/cubit/permissions_state.dart';
import '../../art_core/app_strings.dart';

class AccessLoadingPage extends StatefulWidget {
  const AccessLoadingPage({super.key});
  @override
  State<AccessLoadingPage> createState() => _AccessLoadingPageState();
}

class _AccessLoadingPageState extends State<AccessLoadingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPermissions();
    });
  }

  void _loadPermissions() {
    final user = context.read<LoginCubit>().state.user;
    if (user == null) return;
    final permissions = context.read<PermissionsCubit>();
    final rawRole = user.rawRole?.trim();
    final role = (rawRole == null || rawRole.isEmpty)
        ? user.role.name
        : rawRole;
    if (permissions.hasLoadedAccess(role, user.id, user.loungeId)) return;
    if (permissions.hasAccessIdentity(role, user.id, user.loungeId) &&
        permissions.state.accessStatus == PermissionsStatus.loading)
      return;
    permissions.ensureUserPermissions(
      role,
      loungeId: user.loungeId,
      userId: user.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    final auth = context.watch<LoginCubit>().state;
    final access = context.watch<PermissionsCubit>().state;
    final loungeFailed = auth.loungeLoadError != null;
    final failed =
        loungeFailed || access.accessStatus == PermissionsStatus.failure;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!failed) const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                (failed ? 'venue_access_load_failed' : 'loading_venue_access')
                    .tr(),
                textAlign: TextAlign.center,
              ),
              if (failed)
                TextButton.icon(
                  onPressed: () {
                    if (loungeFailed)
                      context.read<LoginCubit>().reloadLoungeAccess();
                    _loadPermissions();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(AppStrings.retry),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
