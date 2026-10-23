import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../art_core/theme/app_colors.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/station_operational_state.dart';
import '../../../rooms/domain/entities/room_entity.dart';
import '../../../rooms/domain/entities/room_space_type.dart';
import 'room_occupancy_card.dart';
import 'session_ticker.dart';

/// Compact view of every known station, including stations with no booking.
/// Device connectivity and external-vendor reservation state are not inferred.
class StationOverviewGrid extends StatefulWidget {
  final List<StationOperationalState> stations;
  final ValueChanged<Booking> onManage;
  final bool showHeader;

  const StationOverviewGrid({
    super.key,
    required this.stations,
    required this.onManage,
    this.showHeader = true,
  });

  @override
  State<StationOverviewGrid> createState() => _StationOverviewGridState();
}

class _StationOverviewGridState extends State<StationOverviewGrid> {
  String _query = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final now = SessionTickerScope.nowOf(context);
    final stations = widget.stations.where((station) {
      final room = station.room;
      final matches = '${room.nameAr} ${room.nameEn} ${room.resourceType}'
          .toLowerCase()
          .contains(_query.toLowerCase());
      if (!matches) return false;
      if (_filter == 'attention') return station.needsAttention;
      if (_filter == 'available') return station.canClaimAvailable;
      return true;
    }).toList();

    final availableCount = widget.stations
        .where((station) => station.canClaimAvailable)
        .length;
    final activeCount = widget.stations
        .where((station) => station.active != null)
        .length;
    final attentionCount = widget.stations
        .where((station) => station.needsAttention)
        .length;
    final groups = <String, List<StationOperationalState>>{};
    for (final station in stations) {
      groups.putIfAbsent(_groupKey(station.room), () => []).add(station);
    }
    final groupKeys = groups.keys.toList()
      ..sort((a, b) => _groupRank(a).compareTo(_groupRank(b)));

    return Container(
      padding: widget.showHeader ? const EdgeInsets.all(16) : EdgeInsets.zero,
      decoration: widget.showHeader
          ? BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDefault),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader) ...[
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    size: 19,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'stationOverview'.tr(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'stationAuthorityNotice'.tr(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StationMetricChip(
                label: 'stationFilter_all'.tr(),
                value: widget.stations.length,
                color: AppColors.primary,
              ),
              _StationMetricChip(
                label: 'stationFilter_available'.tr(),
                value: availableCount,
                color: AppColors.success,
              ),
              _StationMetricChip(
                label: 'room_occupied'.tr(),
                value: activeCount,
                color: AppColors.neonBlue,
              ),
              _StationMetricChip(
                label: 'stationFilter_attention'.tr(),
                value: attentionCount,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  key: const ValueKey('station_search'),
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.mutedBackground,
                    prefixIcon: const Icon(Icons.search, size: 19),
                    hintText: 'stationSearch'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              for (final filter in ['all', 'available', 'attention'])
                ChoiceChip(
                  label: Text('stationFilter_$filter'.tr()),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (stations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'stationNoMatches'.tr(),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            for (final key in groupKeys) ...[
              // Keep rows aligned within a type even when some stations are idle.
              _StationGroupHeader(
                icon: _groupIcon(key),
                title: _groupLabel(key),
                count: groups[key]!.length,
                attentionCount: groups[key]!
                    .where((station) => station.needsAttention)
                    .length,
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final availableColumns = (width / 230).floor().clamp(1, 5);
                  final cardWidth =
                      ((width - (availableColumns - 1) * 10) / availableColumns)
                          .clamp(0, 320)
                          .toDouble();
                  final hasDetails = groups[key]!.any(
                    (station) =>
                        station.active != null ||
                        station.pending != null ||
                        station.next != null ||
                        station.attentionRequests > 0,
                  );
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final station in groups[key]!)
                        SizedBox(
                          width: cardWidth,
                          height: hasDetails ? 185 : 110,
                          child: _card(context, station, now),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    StationOperationalState station,
    DateTime now,
  ) {
    final active = station.active;
    final pending = station.pending;
    final room = station.room;
    final status = station.activeBookingCount > 1
        ? 'stationManualReview'
        : !station.roomDataFresh
        ? 'stationUnverified'
        : room.status.name == 'maintenance'
        ? 'room_maintenance'
        : active != null
        ? active.isOpenEnded
              ? 'stationOpenTime'
              : active.remainingDuration(now).isNegative
              ? 'stationExpired'
              : active.remainingDuration(now) <= const Duration(minutes: 10)
              ? 'stationEndingSoon'
              : 'room_occupied'
        : room.status.name == 'occupied'
        ? 'stationManualReview'
        : pending != null
        ? 'stationAwaitingConfirmation'
        : station.canClaimAvailable
        ? 'stationAvailableInPlayspot'
        : 'stationUnverified';
    final color = station.needsAttention
        ? AppColors.warning
        : active != null
        ? AppColors.neonBlue
        : station.canClaimAvailable
        ? AppColors.success
        : AppColors.textSecondary;
    final nextAt = station.next?.startDateTime;
    final until = active?.isOpenEnded == true
        ? now.difference(
            active!.openTimeStartedAt ?? active.startDateTime ?? now,
          )
        : active?.remainingDuration(now);
    final duration = until == null
        ? null
        : until.isNegative && active?.isOpenEnded == true
        ? Duration.zero
        : until;
    return Semantics(
      button: true,
      label:
          '${room.nameAr.isNotEmpty ? room.nameAr : room.nameEn}, ${status.tr()}',
      child: Material(
        color: AppColors.mutedBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: ValueKey('station_${room.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (station.activeBookingCount > 1 || !station.roomDataFresh) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('stationManualReview'.tr())),
              );
              return;
            }
            if (active != null) {
              widget.onManage(active);
            } else if (pending != null) {
              widget.onManage(pending);
            } else if (station.canClaimAvailable) {
              showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: RoomOccupancyCard(
                      room: room,
                      loungeId: room.loungeId,
                    ),
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(status.tr())));
            }
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 110),
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderDefault),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _groupIcon(_groupKey(room)),
                        color: color,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        context.locale.languageCode == 'ar' &&
                                room.nameAr.isNotEmpty
                            ? room.nameAr
                            : room.nameEn.isNotEmpty
                            ? room.nameEn
                            : room.nameAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                _StationStatusChip(label: status.tr(), color: color),
                if (active != null) ...[
                  const SizedBox(height: 9),
                  _StationDetailLine(text: active.userName ?? 'anonymous'.tr()),
                  if (duration != null)
                    _StationDetailLine(
                      text:
                          '${active.isOpenEnded ? 'cashier.elapsed'.tr() : 'cashier.remaining'.tr()}: ${duration.inMinutes.abs()}m',
                    ),
                  if (active.isOpenEnded)
                    _StationDetailLine(text: 'stationFinalBillPending'.tr())
                  else if (active.paymentStatus != PaymentStatus.paid)
                    _StationDetailLine(
                      text: 'stationPaymentDue'.tr(),
                      color: AppColors.warning,
                    ),
                ],
                if (pending != null)
                  _StationDetailLine(
                    text: 'stationAwaitingConfirmation'.tr(),
                    color: AppColors.warning,
                  ),
                if (station.attentionRequests > 0)
                  _StationDetailLine(
                    text: 'stationRequests'.tr(
                      namedArgs: {'count': '${station.attentionRequests}'},
                    ),
                    color: AppColors.warning,
                  ),
                if (nextAt != null)
                  _StationDetailLine(
                    text: 'stationNextBooking'.tr(
                      namedArgs: {
                        'time': MaterialLocalizations.of(
                          context,
                        ).formatTimeOfDay(TimeOfDay.fromDateTime(nextAt)),
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _groupKey(RoomEntity room) {
  final space = roomSpaceTypeKey(room.spaceType);
  if (space == 'standard_room' || space == 'vip_room' || space == 'party') {
    return 'rooms';
  }
  final type = room.resourceType.trim().toLowerCase();
  if (type == 'pc') return 'pc';
  if (type == 'console' || type == 'playstation' || type == 'ps') {
    return 'playstation';
  }
  if (type == 'table_sport') {
    final names =
        '${room.activityNames.join(' ')} ${room.nameAr} ${room.nameEn}'
            .toLowerCase();
    if (RegExp(r'billiard|billiards|pool|snooker|بليارد').hasMatch(names)) {
      return 'billiards';
    }
    if (RegExp(
      r'ping.?pong|table.?tennis|تنس.?طاول|بنج|بينج',
    ).hasMatch(names)) {
      return 'table_tennis';
    }
    return 'table_sport';
  }
  return type.isEmpty ? 'other' : type;
}

int _groupRank(String key) {
  const order = [
    'rooms',
    'pc',
    'playstation',
    'billiards',
    'table_tennis',
    'table_sport',
    'vr',
    'simulator',
    'arcade',
    'board_game',
    'other',
  ];
  final index = order.indexOf(key);
  return index < 0 ? order.length : index;
}

String _groupLabel(String key) {
  const known = {
    'rooms': 'stationGroup_rooms',
    'pc': 'stationGroup_pc',
    'playstation': 'stationGroup_playstation',
    'billiards': 'stationGroup_billiards',
    'table_tennis': 'stationGroup_tableTennis',
    'table_sport': 'stationGroup_tableSports',
    'vr': 'stationGroup_vr',
    'simulator': 'stationGroup_simulator',
    'arcade': 'stationGroup_arcade',
    'board_game': 'stationGroup_boardGames',
    'other': 'stationGroup_other',
  };
  return known[key]?.tr() ?? key.replaceAll('_', ' ');
}

IconData _groupIcon(String key) => switch (key) {
  'pc' => Icons.computer_rounded,
  'billiards' => Icons.trip_origin_rounded,
  'table_tennis' || 'table_sport' => Icons.sports_tennis_rounded,
  'rooms' => Icons.meeting_room_rounded,
  'vr' => Icons.view_in_ar_rounded,
  'board_game' => Icons.casino_rounded,
  _ => Icons.sports_esports_rounded,
};

class _StationGroupHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final int attentionCount;

  const _StationGroupHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.attentionCount,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 17, color: AppColors.primary),
      ),
      const SizedBox(width: 9),
      Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.mutedBackground,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          '$count',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Divider(color: AppColors.borderDefault)),
      if (attentionCount > 0) ...[
        const SizedBox(width: 12),
        Icon(Icons.circle, size: 7, color: AppColors.warning),
        const SizedBox(width: 5),
        Text(
          '$attentionCount',
          style: const TextStyle(color: AppColors.warning),
        ),
      ],
    ],
  );
}

class _StationMetricChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StationMetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.mutedBackground,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: AppColors.borderDefault),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          '$value',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );
}

class _StationStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StationStatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

class _StationDetailLine extends StatelessWidget {
  final String text;
  final Color color;

  const _StationDetailLine({
    required this.text,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(color: color),
  );
}
