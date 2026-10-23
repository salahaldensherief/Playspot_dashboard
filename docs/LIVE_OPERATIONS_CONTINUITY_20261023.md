# Live operations continuity — 2026-10-23

Dashboard `dev` contains independently verified scheduler safety PR #77, merged as `86f731fdac8690eb75da6c92d8c8bac33780b76b`. It retains canonical cashier closing while removing the unsafe automatic completion path.

Dashboard PR #75 (`feature/live-operations-stations`) is still Draft. Its current local work includes the station overview UI and `a9e8f04`, which fixes a Flutter `BoxDecoration` assertion caused by rounded corners with differently colored border sides. The regression test renders six mixed PC/PlayStation cards in English and Arabic; both passed. A local web browser showed the six-card English view with content and no console errors. The 20/40 station and final CI checks remain in progress; do not merge the UI PR until the final head is verified. Mobile Open Time financial work remains Draft until exact-schema validation.

Operational boundaries: no production Supabase writes, production deployment, force push, or Google Play publishing. Keep user-facing evidence reports synced to actual commit SHAs and test results after every update.
