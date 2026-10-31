import 'package:easy_localization/easy_localization.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import '../../domain/entities/room_space_type.dart';

String roomSpaceTypeLabel(String? name, {String? fallback}) {
  return switch (roomSpaceTypeKey(name)) {
    'open_area' => AppStrings.openArea,
    'standard_room' => AppStrings.standardRoom,
    'vip_room' => AppStrings.vipRoom,
    'party' => 'room_space_type_party'.tr(),
    'vr' => 'room_space_type_vr'.tr(),
    'console' => 'room_space_type_console'.tr(),
    'gaming station' || 'gaming_station' => 'room_space_type_station'.tr(),
    _ => fallback ?? AppStrings.notAvailable,
  };
}
