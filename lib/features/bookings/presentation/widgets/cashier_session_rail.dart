import 'package:flutter/material.dart';
import '../../domain/entities/booking.dart';
import 'cashier_session_tile.dart';

class CashierSessionRail extends StatelessWidget {
  final List<Booking> bookings;
  final String selectedId;
  final ValueChanged<Booking> onSelect;
  final bool isCompact;
  const CashierSessionRail({
    super.key,
    required this.bookings,
    required this.selectedId,
    required this.onSelect,
    required this.isCompact,
  });
  @override
  Widget build(BuildContext context) => ListView.separated(
    shrinkWrap: isCompact,
    physics: isCompact ? const NeverScrollableScrollPhysics() : null,
    itemCount: bookings.length,
    separatorBuilder: (_, index) => const Divider(height: 1),
    itemBuilder: (_, index) => CashierSessionTile(
      key: ValueKey(bookings[index].id),
      booking: bookings[index],
      selected: selectedId == bookings[index].id,
      onSelect: () => onSelect(bookings[index]),
    ),
  );
}
