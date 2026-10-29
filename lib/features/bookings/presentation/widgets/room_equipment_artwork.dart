import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import '../../domain/entities/booking.dart';
import 'room_session_timer.dart';
import '../../../rooms/domain/entities/room_entity.dart';
import '../../../rooms/domain/entities/room_space_type.dart';

/// Presentation only: never infers device capabilities, prices or permissions.
String equipmentArtworkKey(RoomEntity room) {
  final type = room.resourceType.trim().toLowerCase();
  if (type == 'table_sport') {
    final names = room.activityNames.map((e) => e.trim().toLowerCase()).toSet();
    if (names.any(
      {
        'table_tennis',
        'table tennis',
        'ping pong',
        'تنس الطاولة',
        'بنج',
      }.contains,
    )) {
      return 'table_tennis';
    }
    if (names.any({'billiards', 'billiard', 'pool', 'بلياردو'}.contains)) {
      return 'billiards';
    }
  }
  return switch (type) {
    'console' => 'console',
    'pc' => 'pc',
    'vr' => 'vr',
    'simulator' => 'simulator',
    _ => 'generic',
  };
}

class RoomEquipmentArtwork extends StatelessWidget {
  final RoomEntity room;
  final Color accent;
  const RoomEquipmentArtwork({
    super.key,
    required this.room,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final vip = roomSpaceTypeKey(room.spaceType) == 'vip_room';
    return RepaintBoundary(
      child: ExcludeSemantics(
        // The room name, activity and status remain accessible Flutter text.
        child: Container(
          height: 166,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (vip ? const Color(0xff9d7bd2) : accent).withValues(alpha: .16),
                const Color(0xff0c1424),
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: .16)),
          ),
          child: SvgPicture.asset(
            'assets/equipment/equipment-${equipmentArtworkKey(room)}.svg',
            fit: BoxFit.contain,
            placeholderBuilder: (_) =>
                Icon(Icons.devices_outlined, color: accent, size: 48),
            errorBuilder: (_, _, _) =>
                Icon(Icons.devices_outlined, color: accent, size: 48),
          ),
        ),
      ),
    );
  }
}

/// Screen overlays use the original SVG viewBox, never mirrored for RTL.
/// Enlarged text gets natural-height space instead of shrinking or clipping.
class RoomEquipmentHero extends StatelessWidget {
  final RoomEntity room;
  final Color accent;
  final Booking? booking;
  const RoomEquipmentHero({
    super.key,
    required this.room,
    required this.accent,
    this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final art = RoomEquipmentArtwork(room: room, accent: accent);
    final session = booking;
    if (session == null) return art;
    final timer = RoomSessionTimer(booking: session);
    if (MediaQuery.textScalerOf(context).scale(30) > 37.5) {
      return Column(
        children: [
          art,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: timer,
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = ['console', 'pc'].contains(equipmentArtworkKey(room));
        final scale = math.min(constraints.maxWidth / 360, 166 / 220);
        final left = (constraints.maxWidth - 360 * scale) / 2;
        final top = (166 - 220 * scale) / 2;
        return Stack(
          children: [
            art,
            Positioned(
              left: screen ? left + 49 * scale : 12,
              top: screen ? top + 27 * scale : null,
              width: screen ? 201 * scale : null,
              height: screen ? 110 * scale : null,
              right: screen ? null : 12,
              bottom: screen ? null : 8,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(
                    0xff0b1628,
                  ).withValues(alpha: screen ? .7 : .94),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: timer,
              ),
            ),
          ],
        );
      },
    );
  }
}
