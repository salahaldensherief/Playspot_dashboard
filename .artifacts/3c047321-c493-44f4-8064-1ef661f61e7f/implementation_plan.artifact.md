# Comprehensive UI Refinement Plan for Play Spot Dashboard

Refining and polishing all core widgets (`BookingCard`, `LiveSessionCard`, `RoomOccupancyGrid`, `BookingDetailsDialog`, `AddBookingDialog`) to ensure they impeccably display all model properties (pricing, discounts, add-ons, canteen orders, multi-room bookings, customer visit stats, and live session timers).

## Proposed Changes

### Bookings & Sessions UI Refinement
- **[BookingCard](file:///D:/flutter_projects/play_spot_dashboard/lib/features/bookings/presentation/widgets/booking_card.dart)**: Enhance visual hierarchy, state badges, price breakdown, discount badges, extras/canteen orders preview, and quick actions.
- **[LiveSessionCard](file:///D:/flutter_projects/play_spot_dashboard/lib/features/bookings/presentation/widgets/live_session_card.dart)**: Polish active timer indicators, session progress rings, room specifications, quick extension & end session controls, and order items.
- **[RoomOccupancyGrid](file:///D:/flutter_projects/play_spot_dashboard/lib/features/bookings/presentation/widgets/room_occupancy_grid.dart)**: Refine room card statuses (available, occupied, pending, reserved), filter chips, and quick booking initiation.
- **[BookingDetailsDialog](file:///D:/flutter_projects/play_spot_dashboard/lib/features/bookings/presentation/widgets/booking_details_dialog.dart)**: Comprehensive breakdown of financial totals, voucher info, discount reasons, payment status, customer contact info, and receipt preview.
- **[AddBookingDialog](file:///D:/flutter_projects/play_spot_dashboard/lib/features/bookings/presentation/widgets/add_booking_dialog.dart)**: Streamline multi-room booking support, date/time pickers, dynamic pricing calculation, extras selection, and customer lookup.

## Verification Plan
- Verify compilation and UI rendering across all refined widgets.
- Ensure correct data model binding (prices, discounts, multi-room selections, session durations).
