import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
