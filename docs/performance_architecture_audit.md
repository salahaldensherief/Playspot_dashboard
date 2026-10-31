# Performance and lifecycle review

This review inspected refresh concurrency, rebuild scope, timer/subscription ownership and shared presentation. It is not a browser frame-rate or heap benchmark.

| Area | Finding and change | Verification |
| --- | --- | --- |
| Booking/session/requests streams | `refreshingStream` owns initial load, debounce, fallback polling, pause/resume and cancellation. Fetches are serialized; an invalidation arriving during a fetch produces a follow-up instead of being dropped. Cancellation suppresses late responses and releases timers/subscriptions. | Regression tests for bursts, cancellation, pause/resume, failed fetch recovery and unavailable realtime. |
| Lounge scope | Active-session realtime invalidations are filtered by lounge, matching the existing scoped RPC read. Authorization failures still cannot fall back to a weaker table query. | Existing HTTP/RPC read and denial contract tests. |
| Room card rendering | Remove the card's periodic `setState`. Only the remaining-time bar depends on the clock; customer details, room specs and action buttons no longer rebuild each second. | Clock build-count tests and existing responsive session workspace tests. |
| Shared clock | Reuse `SessionClockHost` for booking countdowns and page clock ownership. Timers stop when hidden or backgrounded; nested default hosts reuse their parent. | Hide/background/resume/disposal widget tests. |
| Tournament audit | Generation guards reject callbacks from replaced subscriptions; disposal prevents future subscriptions and late audit results. | Subscription replacement/disposal regression. |
| Requests realtime | Move channel setup/cleanup into an invalidation adapter. Use a unique channel name for each watcher and await channel removal. Data retrieval remains in the data source; refresh scheduling is shared. | Analyze, existing request/shift contracts and shared refresh lifecycle tests. |

The reusable refresh coordinator separates scheduling and resource ownership from each feature's fetch strategy. It depends on injected functions and streams rather than Supabase. Data sources retain DTO/RPC decisions. The existing Cubit/repository pattern remains responsible for domain orchestration. A pattern was not introduced solely because a class is large.

Other reviewed ownership paths include booking page controllers, realtime watcher mixin, tournament Cubit close and requests/channel subscriptions. A controller that is cleaned up is not classified as a leak merely because its type appears in a scan. Large pricing, combo editor, payment and shift files remain candidates for feature-specific decomposition; this change does not claim every duplicate in the repository has been removed.

## Browser verification still required

Build/run Flutter Web in profile mode. Record a populated live sessions workspace, requests bursts, repeated navigation and tab hide/resume. Compare frame build/raster timings and retained listeners/controllers after warm-up and repeated navigation. Test different lounge roles, RTL/LTR, 360/768/1440 widths and large text; retain the same booking dataset for before/after comparisons. Measure browser heap and Flutter allocations separately; no device/browser memory improvement percentage is claimed here.

Use Flutter CI for analysis, the full test suite, auth runtime tests and release web compilation. `Dart formatting review` emits a review patch and does not write to the branch.
