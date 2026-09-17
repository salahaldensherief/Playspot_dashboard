import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/core/utils/debouncer.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';

class BookingFilterState {
  final String searchQuery;
  final String? selectedRoomId;
  final BookingStatus? selectedStatus;
  final String? selectedTimeFilter;

  const BookingFilterState({
    this.searchQuery = '',
    this.selectedRoomId,
    this.selectedStatus,
    this.selectedTimeFilter,
  });

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      selectedRoomId != null ||
      selectedStatus != null ||
      selectedTimeFilter != null;

  BookingFilterState copyWith({
    String? searchQuery,
    String? selectedRoomId,
    BookingStatus? selectedStatus,
    String? selectedTimeFilter,
    bool clearRoom = false,
    bool clearStatus = false,
    bool clearTime = false,
  }) {
    return BookingFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRoomId: clearRoom ? null : (selectedRoomId ?? this.selectedRoomId),
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      selectedTimeFilter: clearTime ? null : (selectedTimeFilter ?? this.selectedTimeFilter),
    );
  }
}

class _RoomFilterOption {
  final String? id;
  final String name;
  const _RoomFilterOption({this.id, required this.name});
}

class _StatusFilterOption {
  final BookingStatus? status;
  final String name;
  const _StatusFilterOption({this.status, required this.name});
}

class _TimeFilterOption {
  final String? key;
  final String name;
  const _TimeFilterOption({this.key, required this.name});
}

class BookingFilterBar extends StatefulWidget {
  final BookingFilterState filterState;
  final ValueChanged<BookingFilterState> onFilterChanged;
  final VoidCallback onResetFilters;

  const BookingFilterBar({
    super.key,
    required this.filterState,
    required this.onFilterChanged,
    required this.onResetFilters,
  });

  @override
  State<BookingFilterBar> createState() => _BookingFilterBarState();
}

class _BookingFilterBarState extends State<BookingFilterBar> {
  late TextEditingController _searchController;
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 400));

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.filterState.searchQuery);
  }

  @override
  void didUpdateWidget(covariant BookingFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterState.searchQuery != _searchController.text) {
      _searchController.text = widget.filterState.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 800;

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNarrow) ...[
                _buildSearchTextField(),
                SizedBox(height: 10.h),
                _buildRoomDropdown(context),
                SizedBox(height: 10.h),
                _buildStatusDropdown(),
                SizedBox(height: 10.h),
                _buildTimeDropdown(),
                if (widget.filterState.hasActiveFilters) ...[
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: widget.onResetFilters,
                      icon: Icon(Icons.clear_all_rounded, color: AppColors.danger, size: 16.r),
                      label: AppText.body(AppStrings.resetFilters, color: AppColors.danger, fontSize: 11.sp),
                    ),
                  ),
                ],
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildSearchTextField(),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      flex: 2,
                      child: _buildRoomDropdown(context),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      flex: 2,
                      child: _buildStatusDropdown(),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      flex: 2,
                      child: _buildTimeDropdown(),
                    ),
                    if (widget.filterState.hasActiveFilters) ...[
                      SizedBox(width: 10.w),
                      IconButton(
                        icon: Icon(Icons.clear_all_rounded, color: AppColors.danger, size: 20.r),
                        tooltip: AppStrings.resetFilters,
                        onPressed: widget.onResetFilters,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
  }

  Widget _buildSearchTextField() {
    return AppTextField(
      controller: _searchController,
      hintText: AppStrings.userSearchHint,
      prefixIcon: Icons.search_rounded,
      suffix: _searchController.text.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.close, size: 16.r, color: AppColors.textMuted),
              onPressed: () {
                _searchDebouncer.cancel();
                _searchController.clear();
                widget.onFilterChanged(widget.filterState.copyWith(searchQuery: ''));
              },
            )
          : null,
      onChanged: (val) {
        _searchDebouncer.run(() {
          widget.onFilterChanged(widget.filterState.copyWith(searchQuery: val));
        });
      },
    );
  }

  Widget _buildRoomDropdown(BuildContext context) {
    return BlocBuilder<RoomCubit, RoomState>(
      buildWhen: (prev, curr) => prev.rooms != curr.rooms,
      builder: (context, state) {
        final rooms = state.rooms;
        final roomOptions = <_RoomFilterOption>[
          _RoomFilterOption(id: null, name: AppStrings.rooms),
          ...rooms.map((r) => _RoomFilterOption(id: r.id, name: r.nameAr.isNotEmpty ? r.nameAr : r.nameEn)),
        ];

        final currentOption = roomOptions.firstWhere(
          (opt) => opt.id == widget.filterState.selectedRoomId,
          orElse: () => roomOptions.first,
        );

        return CustomDropdown<_RoomFilterOption>(
          label: '',
          value: currentOption,
          items: roomOptions,
          itemLabel: (opt) => opt.name,
          onChanged: (opt) {
            final val = opt?.id;
            widget.onFilterChanged(widget.filterState.copyWith(selectedRoomId: val, clearRoom: val == null));
          },
        );
      },
    );
  }

  Widget _buildStatusDropdown() {
    final statusOptions = <_StatusFilterOption>[
      _StatusFilterOption(status: null, name: AppStrings.filterByStatus),
      _StatusFilterOption(status: BookingStatus.pending, name: AppStrings.pending),
      _StatusFilterOption(status: BookingStatus.upcoming, name: AppStrings.upcoming),
      _StatusFilterOption(status: BookingStatus.inProgress, name: AppStrings.inProgress),
      _StatusFilterOption(status: BookingStatus.completed, name: AppStrings.completed),
      _StatusFilterOption(status: BookingStatus.cancelled, name: AppStrings.cancelled),
    ];

    final currentOption = statusOptions.firstWhere(
      (opt) => opt.status == widget.filterState.selectedStatus,
      orElse: () => statusOptions.first,
    );

    return CustomDropdown<_StatusFilterOption>(
      label: '',
      value: currentOption,
      items: statusOptions,
      itemLabel: (opt) => opt.name,
      onChanged: (opt) {
        final val = opt?.status;
        widget.onFilterChanged(widget.filterState.copyWith(selectedStatus: val, clearStatus: val == null));
      },
    );
  }

  Widget _buildTimeDropdown() {
    final timeOptions = <_TimeFilterOption>[
      _TimeFilterOption(key: null, name: AppStrings.filterByDate),
      _TimeFilterOption(key: 'current_shift', name: AppStrings.currentShift),
      _TimeFilterOption(key: 'morning', name: AppStrings.morningPeriod),
      _TimeFilterOption(key: 'evening', name: AppStrings.eveningPeriod),
    ];

    final currentOption = timeOptions.firstWhere(
      (opt) => opt.key == widget.filterState.selectedTimeFilter,
      orElse: () => timeOptions.first,
    );

    return CustomDropdown<_TimeFilterOption>(
      label: '',
      value: currentOption,
      items: timeOptions,
      itemLabel: (opt) => opt.name,
      onChanged: (opt) {
        final val = opt?.key;
        widget.onFilterChanged(widget.filterState.copyWith(selectedTimeFilter: val, clearTime: val == null));
      },
    );
  }
}
