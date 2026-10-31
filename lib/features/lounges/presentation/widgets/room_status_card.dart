import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';

/// Displays server-backed room status, without cosmetic local switches.
class RoomStatusCard extends StatelessWidget {
  const RoomStatusCard({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<RoomCubit, RoomState>(
    buildWhen: (previous, current) =>
        previous.rooms != current.rooms || previous.status != current.status,
    builder: (context, state) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'room_operational_status'.tr(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (state.status == RoomStatus.failure)
            Text(
              'dashboard_data_unavailable'.tr(),
              style: const TextStyle(color: AppColors.warning),
            )
          else if (state.status == RoomStatus.initial ||
              state.status == RoomStatus.loading)
            const LinearProgressIndicator()
          else if (state.rooms.isEmpty)
            Text(
              AppStrings.noRoomsAdded,
              style: const TextStyle(color: AppColors.textSecondary),
            )
          else
            for (var i = 0; i < state.rooms.length; i++) ...[
              if (i > 0) const Divider(height: 20, color: AppColors.divider),
              _RoomStatusRow(room: state.rooms[i]),
            ],
        ],
      ),
    ),
  );
}

class _RoomStatusRow extends StatelessWidget {
  const _RoomStatusRow({required this.room});
  final RoomEntity room;
  @override
  Widget build(BuildContext context) {
    final status = room.status == RoomStatusEnum.occupied
        ? RoomStatusEnum.occupied
        : (!room.isAvailable ? RoomStatusEnum.maintenance : room.status);
    final (label, color, icon) = switch (status) {
      RoomStatusEnum.available => (
        AppStrings.availableStatus,
        AppColors.success,
        Icons.check_circle_outline,
      ),
      RoomStatusEnum.maintenance => (
        AppStrings.maintenanceStatus,
        AppColors.warning,
        Icons.build_outlined,
      ),
      RoomStatusEnum.occupied => (
        AppStrings.occupiedStatus,
        AppColors.neonPurple,
        Icons.sports_esports_outlined,
      ),
    };
    final preferred = context.locale.languageCode == 'ar'
        ? room.nameAr
        : room.nameEn;
    final fallback = context.locale.languageCode == 'ar'
        ? room.nameEn
        : room.nameAr;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            preferred.trim().isEmpty ? fallback : preferred,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label, style: TextStyle(color: color, fontSize: 13)),
        ),
      ],
    );
  }
}
