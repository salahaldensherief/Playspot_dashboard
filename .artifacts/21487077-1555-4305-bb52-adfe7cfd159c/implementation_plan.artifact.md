# Implementation Plan - Frontend Updates for Backend Features

Implement frontend support for Menu Inventory, Shift Approval, Live Room Swap, and Discount Caps.

## Proposed Changes

### 1. Menu & Stock Management (features/lounges)

#### [MODIFY] [extra_entity.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/lounges/domain/entities/extra_entity.dart)
- Add `stockQuantity`, `trackStock`, `minStockAlert` fields.

#### [MODIFY] [extra_model.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/lounges/data/models/extra_model.dart)
- Update `fromJson` and `toJson` to map backend fields: `stock_quantity`, `track_stock`, `min_stock_alert`.

#### [MODIFY] [extra_dialog.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/lounges/presentation/widgets/extra_dialog.dart)
- Add UI controls for stock tracking:
    - `SwitchListTile` for "Track Stock".
    - `AppTextField` for "Stock Quantity" and "Low Stock Threshold" (enabled only when tracking is on).

#### [MODIFY] [extra_card.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/lounges/presentation/widgets/extra_card.dart)
- Show warning badge if `stockQuantity <= minStockAlert`.
- Dim card and disable interactions if `stockQuantity == 0 && trackStock == true`.

---

### 2. Shift Approval Workflow (features/shifts)

#### [MODIFY] [shift_entity.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/shifts/domain/entities/shift_entity.dart)
- Add `isApproved`, `approvedBy`, `approvedAt`, `managerNotes` fields.

#### [MODIFY] [shift_model.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/shifts/data/models/shift_model.dart)
- Update `fromJson` and `toJson` to map: `is_approved`, `approved_by`, `approved_at`, `manager_notes`.

#### [MODIFY] [shift_repository.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/shifts/domain/repositories/shift_repository.dart) & [shift_repository_impl.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/shifts/data/repositories/shift_repository_impl.dart)
- Add `approveShift(String shiftId, String managerId, String? notes)` method.

#### [MODIFY] [shift_remote_data_source.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/shifts/data/data_sources/shift_remote_data_source.dart)
- Implement `approveShift` calling `supabase.rpc('approve_shift', ...)`.

#### [MODIFY] [shift_cubit.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/shifts/presentation/shift_management/shift_cubit.dart)
- Add `approveShift` method.

#### [MODIFY] [shift_history_screen.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/shifts/presentation/shift_history/shift_history_screen.dart)
- Add approval status chip.
- Show "Approve Shift" button for managers/admins.

---

### 3. Live Room Swap (features/rooms & features/bookings)

#### [MODIFY] [booking_repository.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/domain/repositories/booking_repository.dart) & [booking_repository_impl.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/data/repositories/booking_repository_impl.dart)
- Add `swapRoom(String bookingId, String newRoomId, String actionBy)` method.

#### [MODIFY] [booking_remote_data_source.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/data/datasources/booking_remote_data_source.dart)
- Implement `swapRoom` calling `supabase.rpc('swap_booking_room', ...)`.

#### [MODIFY] [booking_cubit.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/presentation/cubit/booking_cubit.dart)
- Add `swapRoom` method with optimistic updates for local state.

#### [MODIFY] [booking_details_dialog.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/presentation/widgets/booking_details_dialog.dart)
- Add "Swap Room" action button.

#### [NEW] [swap_room_dialog.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/presentation/widgets/swap_room_dialog.dart)
- A dialog to select a new available room and confirm the swap.

---

### 4. Checkout Discounts & Audit (features/bookings)

#### [MODIFY] [booking_details_dialog.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/presentation/widgets/booking_details_dialog.dart)
- Expand the payment section to include:
    - Discount Amount/Percentage input.
    - Discount Reason input (required if discount > 0).
    - Validation for Cashier role (max 10% discount).

#### [MODIFY] [confirm_cash_payment.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/domain/usecases/confirm_cash_payment.dart)
- Update to accept `discountAmount`, `discountPercentage`, and `discountReason`.

#### [MODIFY] [booking_repository.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/domain/repositories/booking_repository.dart) & [booking_repository_impl.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/data/repositories/booking_repository_impl.dart)
- Update `confirmCashPayment` signature.

---

### 5. Shared / Localization

#### [MODIFY] [app_strings.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/art_core/app_strings.dart)
- Add new string keys.

#### [MODIFY] [en.json](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/assets/translations/en.json) & [ar.json](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/assets/translations/ar.json)
- Add localized values for the new features.

## Verification Plan

### Automated Tests
- N/A (Unit tests could be added for models and cubits if desired, but focus is on implementation).

### Manual Verification
1. **Menu & Stock**:
    - Add an item with "Track Stock" enabled and set quantity.
    - Verify badge appears when quantity is low.
    - Verify item is dimmed and disabled when quantity is zero.
2. **Shift Approval**:
    - Close a shift as cashier.
    - Login as manager/admin, go to Shift History, and approve the shift with notes.
    - Verify status chip updates.
3. **Room Swap**:
    - Open an active booking details.
    - Select "Swap Room", choose another available room.
    - Verify the booking room updates in the UI.
4. **Checkout Discounts**:
    - Perform checkout as cashier, try 15% discount -> expect error.
    - Perform checkout as cashier, try 5% discount with reason -> expect success.
    - Verify discount amount and reason are sent to backend.
