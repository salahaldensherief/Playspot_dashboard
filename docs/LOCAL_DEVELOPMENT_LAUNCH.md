# Local Dashboard launch on Windows

The Dashboard requires an explicit hosted Supabase project. There is no production fallback. The separate `playspot-demo` project supports limited exploration, but its schema does not yet contain the canonical checkout, deposit verification, staff-permission, or money-movement contract. Do not use it for financial acceptance.

1. Create an ignored `.env.demo` in the Dashboard repository root with `SUPABASE_URL=https://tmqhncduzlavgqoyjcmn.supabase.co` and the matching **public** `SUPABASE_ANON_KEY`. Existing local demo settings are in `D:\PlaySpotDemoRuntime\private\client-demo.json`; keep account credentials and privileged keys out of the repository.
2. From PowerShell in the repository root, run `./scripts/launch_local.ps1 -Environment Demo -ValidateOnly`, then `./scripts/launch_local.ps1 -Environment Demo`. Use `-Device edge` if preferred.
3. For a separately prepared development backend, create ignored `.env.dev` with that project's URL and public key, then run the same commands with `-Environment Development`. The script rejects the production project, a demo project mislabeled as development, a mismatched legacy anon key, and service-role keys.

The script accepts a JSON configuration path using `-ConfigFile` if it has `SUPABASE_URL` and `SUPABASE_ANON_KEY` fields. It passes only those two values to Flutter through a temporary file, deletes that file on exit, and prints only the environment and project reference. The `.env*` files are ignored by Git. Never put a service-role key in a Flutter build.

VS Code/Antigravity launch configurations still accept an ignored `.env` file. Copy the same two fields from the selected `.env.demo` or `.env.dev` into `.env` before using those configurations. A client build is not proof that the corresponding SQL migrations are applied or that Auth, RLS and payment flows pass.
