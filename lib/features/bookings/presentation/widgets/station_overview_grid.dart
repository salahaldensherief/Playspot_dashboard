import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../art_core/theme/app_colors.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/station_operational_state.dart';
import 'room_occupancy_card.dart';
import 'session_ticker.dart';

/// Compact view of every known station, including stations with no booking.
/// Device connectivity and external-vendor reservation state are not inferred.
class StationOverviewGrid extends StatefulWidget {
  final List<StationOperationalState> stations;
  final ValueChanged<Booking> onManage;

  const StationOverviewGrid({
    super.key,
    required this.stations,
    required this.onManage,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'stationOverview'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'stationAuthorityNotice'.tr(),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 240,
              child: TextField(
                key: const ValueKey('station_search'),
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  labelText: 'stationSearch'.tr(),
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
        const SizedBox(height: 12),
        if (stations.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'stationNoMatches'.tr(),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = (width / 210).floor().clamp(1, 6);
              final cardWidth = (width - (columns - 1) * 8) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final station in stations)
                    SizedBox(
                      width: cardWidth,
                      child: _card(context, station, now),
                    ),
                ],
              );
            },
          ),
      ],
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: ValueKey('station_${room.id}'),
          borderRadius: BorderRadius.circular(10),
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
            constraints: const BoxConstraints(minHeight: 148),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      room.resourceType == 'pc'
                          ? Icons.computer
                          : Icons.sports_esports,
                      color: color,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
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
                const SizedBox(height: 4),
                Text(
                  '${room.resourceType.toUpperCase()} · ${status.tr()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 12),
                ),
                if (active != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    active.userName ?? 'anonymous'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (duration != null)
                    Text(
                      '${active.isOpenEnded ? 'cashier.elapsed'.tr() : 'cashier.remaining'.tr()}: ${duration.inMinutes.abs()}m',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  if (active.isOpenEnded)
                    Text(
                      'stationFinalBillPending'.tr(),
                      style: const TextStyle(color: AppColors.textSecondary),
                    )
                  else if (active.paymentStatus != PaymentStatus.paid)
                    Text(
                      'stationPaymentDue'.tr(),
                      style: const TextStyle(color: AppColors.warning),
                    ),
                ],
                if (pending != null)
                  Text(
                    'stationAwaitingConfirmation'.tr(),
                    style: const TextStyle(color: AppColors.warning),
                  ),
                if (station.attentionRequests > 0)
                  Text(
                    'stationRequests'.tr(
                      namedArgs: {'count': '${station.attentionRequests}'},
                    ),
                    style: const TextStyle(color: AppColors.warning),
                  ),
                if (nextAt != null)
                  Text(
                    'stationNextBooking'.tr(
                      namedArgs: {
                        'time': MaterialLocalizations.of(
                          context,
                        ).formatTimeOfDay(TimeOfDay.fromDateTime(nextAt)),
                      },
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
