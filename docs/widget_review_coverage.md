# Widget review coverage — 2026-10-07

This records **automated inventory** separately from **targeted manual review**. It does not certify a widget-by-widget review or issue-free runtime behavior.

Baseline `82f3894`: 931 Dart files under `lib`; 410 classes explicitly extending StatelessWidget/StatefulWidget. Counts use text patterns, not an AST, and exclude other widget base classes. They describe the baseline, not runtime builds or final class counts.

Every feature received automated checks for widget/state declarations, setState, periodic timers, network images, shrink-wrapped lists, intrinsic layout and local controller creation. No flags does not prove correctness.

| Feature | Dart files | Widget classes | Coverage |
| --- | ---: | ---: | --- |
| analytics | 69 | 55 | Automated inventory plus targeted manual paths; not the whole feature |
| audit | 20 | 8 | Automated inventory; no complete manual feature review claimed |
| auth | 16 | 2 | Automated inventory; no complete manual feature review claimed |
| bookings | 123 | 92 | Automated inventory plus targeted manual paths; not the whole feature |
| canteen | 33 | 6 | Automated inventory; no complete manual feature review claimed |
| categories | 23 | 5 | Automated inventory; no complete manual feature review claimed |
| core/shared | 95 | 49 | Automated inventory plus targeted manual paths; not the whole feature |
| kyc | 21 | 8 | Automated inventory; no complete manual feature review claimed |
| lounges | 58 | 31 | Automated inventory; no complete manual feature review claimed |
| loyalty | 31 | 13 | Automated inventory; no complete manual feature review claimed |
| marketing | 23 | 8 | Automated inventory; no complete manual feature review claimed |
| offline_cashier | 59 | 5 | Automated inventory; no complete manual feature review claimed |
| onboarding | 33 | 10 | Automated inventory; no complete manual feature review claimed |
| payouts | 19 | 10 | Automated inventory; no complete manual feature review claimed |
| permissions | 15 | 1 | Automated inventory; no complete manual feature review claimed |
| pricing | 20 | 6 | Automated inventory; no complete manual feature review claimed |
| requests | 32 | 15 | Automated inventory plus targeted manual paths; not the whole feature |
| reviews | 16 | 6 | Automated inventory plus targeted manual paths; not the whole feature |
| rooms | 20 | 9 | Automated inventory; no complete manual feature review claimed |
| shifts | 48 | 19 | Automated inventory plus targeted manual paths; not the whole feature |
| splash | 1 | 1 | Automated inventory; no complete manual feature review claimed |
| staff | 18 | 4 | Automated inventory; no complete manual feature review claimed |
| support | 32 | 8 | Automated inventory; no complete manual feature review claimed |
| system | 26 | 9 | Automated inventory; no complete manual feature review claimed |
| tournaments | 55 | 22 | Automated inventory plus targeted manual paths; not the whole feature |
| users | 25 | 8 | Automated inventory plus targeted manual paths; not the whole feature |

## Candidate contexts inspected

The following flagged construction/layout contexts were inspected. This is not complete screen/data-flow review. Dynamic nested lists still need large-data profiling; a shrinkWrap flag alone is not justification for replacing a layout with Expanded. Fixed KPI grids, capped top lounges/review cards and constrained scrollable dialogs were retained. Intrinsic timeline/schedule rows equalize neighboring heights; their cost needs measurement.

| Path | Original inventory flags |
| --- | --- |
| `lib/art_core/widgets/shimmer_loading.dart` | shrink_wrap |
| `lib/art_core/widgets/data_table_widget.dart` | shrink_wrap |
| `lib/art_core/layouts/top_bar/top_bar_branch_switcher.dart` | shrink_wrap |
| `lib/features/lounges/presentation/widgets/extras_grid.dart` | shrink_wrap |
| `lib/features/loyalty/presentation/widgets/loyalty_stats_tab.dart` | shrink_wrap |
| `lib/features/loyalty/presentation/widgets/levels_tab.dart` | shrink_wrap |
| `lib/features/users/presentation/widgets/super_admin_ban_queue_section.dart` | shrink_wrap, review_owner:controller |
| `lib/features/tournaments/presentation/tournaments_screen.dart` | review_owner:reasonController |
| `lib/features/tournaments/presentation/widgets/audit_logs_modal.dart` | shrink_wrap |
| `lib/features/tournaments/presentation/widgets/tournament_prizes_dialog.dart` | shrink_wrap |
| `lib/features/tournaments/presentation/widgets/tournament_placement_card.dart` | shrink_wrap |
| `lib/features/bookings/presentation/widgets/customer_cancellation_history_dialog.dart` | shrink_wrap |
| `lib/features/bookings/presentation/widgets/online_booking_status.dart` | timer_rebuild |
| `lib/features/bookings/presentation/widgets/start_session_button.dart` | timer_rebuild |
| `lib/features/bookings/presentation/widgets/bookings_active_grid.dart` | shrink_wrap |
| `lib/features/bookings/presentation/widgets/cashier_sessions_workspace_state.dart` | timer_rebuild |
| `lib/features/bookings/presentation/widgets/booking_card_schedule_box.dart` | intrinsic_layout |
| `lib/features/bookings/presentation/widgets/booking_session_progress.dart` | timer_rebuild |
| `lib/features/audit/presentation/widgets/audit_event_details_dialog.dart` | shrink_wrap |
| `lib/features/audit/presentation/widgets/audit_timeline.dart` | shrink_wrap |
| `lib/features/audit/presentation/widgets/audit_mobile_list.dart` | shrink_wrap |
| `lib/features/support/presentation/lounge_owner_support_screen.dart` | shrink_wrap |
| `lib/features/permissions/presentation/views/lounge_permissions_settings_tab.dart` | shrink_wrap |
| `lib/features/canteen/presentation/widgets/canteen_upsell_tab.dart` | shrink_wrap |
| `lib/features/canteen/presentation/widgets/canteen_combos_tab.dart` | shrink_wrap |
| `lib/features/canteen/presentation/widgets/combo_editor_modal.dart` | shrink_wrap |
| `lib/features/analytics/presentation/widgets/cockpit_kpi_grid.dart` | shrink_wrap |
| `lib/features/analytics/presentation/widgets/pending_extensions_card.dart` | shrink_wrap |
| `lib/features/analytics/presentation/widgets/dashboard_stats_grid.dart` | shrink_wrap |
| `lib/features/analytics/presentation/widgets/top_lounges_card.dart` | shrink_wrap |
| `lib/features/analytics/presentation/widgets/lounge_owner_analytics_grid.dart` | shrink_wrap |
| `lib/features/pricing/presentation/widgets/pricing_grouped_rules_list.dart` | shrink_wrap |
| `lib/features/shifts/presentation/shift_history/shift_history_screen.dart` | review_owner:notesController |
| `lib/features/shifts/presentation/shift_management/widgets/admin_shift_monitoring_bar.dart` | timer_rebuild |
| `lib/features/shifts/presentation/shift_management/widgets/shift_kpi_cards.dart` | shrink_wrap |
| `lib/features/shifts/presentation/shift_management/widgets/shift_financial_summary_tab.dart` | shrink_wrap |
| `lib/features/reviews/presentation/reviews_screen.dart` | shrink_wrap |
| `lib/features/reviews/presentation/widgets/lounge_reviews_card.dart` | shrink_wrap |
| `lib/features/onboarding/presentation/widgets/assets_step.dart` | shrink_wrap |
| `lib/features/onboarding/presentation/widgets/marketplace_step.dart` | shrink_wrap |

## Follow-up fixes

Three dialogs now store text through onChanged instead of constructing unowned TextEditingControllers. TextFormField owns/disposes its internal controller. SessionTimeSelector keeps static live-card content stable until warning/expiry phase or parent input changes; only the timer ticks each second. A regression counts builds across ticks, expiry and parent updates. Reviews reuse refreshingStream with the existing 10-second fallback poll, serializing fetches and suppressing late results after cancellation. Earlier targeted paths include booking/analytics/requests streams, tournament audit lifecycle and shared clock consumers.

## Verification limits

Additional resource checks traced the cashier classification timer, schedule intrinsic layout and system status watcher. AppStatusCubit now initializes its watcher once, rejects checks after close, stops polling and awaits channel removal after marking the Cubit closed. Regressions cover repeated initialization, delayed cleanup and late status results. These checks do not certify every controller/dialog in the other features.

Flutter CI runs analysis, the full automated tests and release compilation. Physical-device/browser CPU/GPU profiling and retained-heap measurements are unavailable locally. Every screen's appearance, every live role/backend flow and all duplicated UI have **not** been exhaustively verified. See [performance_architecture_audit.md](performance_architecture_audit.md) for the profiling procedure and earlier changes.
