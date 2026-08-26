import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import '../cubit/room_cubit.dart';
import '../cubit/room_state.dart';
import 'rooms_data_table.dart';

class RoomTableSection extends StatefulWidget {
  const RoomTableSection({super.key});

  @override
  State<RoomTableSection> createState() => _RoomTableSectionState();
}

class _RoomTableSectionState extends State<RoomTableSection> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterChips(),
        SizedBox(height: 24.h),
        BlocBuilder<RoomCubit, RoomState>(
          builder: (context, state) {
            if (state.status == RoomStatus.loading) {
              return const TableShimmer(columns: 5);
            }

            if (state.status == RoomStatus.success) {
              final filteredRooms = _selectedFilter == 'all'
                  ? state.rooms
                  : state.rooms.where((r) => r.spaceTypeId == _selectedFilter).toList();
              return RoomsDataTable(rooms: filteredRooms);
            }

            if (state.status == RoomStatus.failure) {
              return Center(child: Text(state.errorMessage ?? AppStrings.error, style: const TextStyle(color: AppColors.danger)));
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = {
      'all': AppStrings.all,
      'open_area': AppStrings.openArea,
      'standard_room': AppStrings.standardRoom,
      'vip_room': AppStrings.vipRoom,
    };

    return Wrap(
      spacing: 12.w,
      children: filters.entries.map((entry) {
        final isSelected = _selectedFilter == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedFilter = entry.key);
            }
          },
          backgroundColor: AppColors.mutedBackground,
          selectedColor: AppColors.neonBlue,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
