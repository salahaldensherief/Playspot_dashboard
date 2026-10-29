$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('playspot-launch-test-' + [guid]::NewGuid().ToString('N') + '.json')
$passed = 0
# Any attempt to validate through a hosted HTTP call must fail this test.
function Invoke-WebRequest { throw 'TEST_FORBIDS_NETWORK' }
function Test-Configuration($name, $url, $key, $expectedError) {
  @{SUPABASE_URL=$url; SUPABASE_ANON_KEY=$key} | ConvertTo-Json | Set-Content $temporary
  $failure = $null
  try { & "$root/scripts/launch_local.ps1" -Environment Development -ConfigFile $temporary -ValidateOnly | Out-Null }
  catch { $failure = $_.Exception.Message }
  if ($expectedError) {
    if (-not $failure -or $failure -notlike "*$expectedError*") { throw "FAIL $name (unexpected validation result)" }
  } elseif ($failure) { throw "FAIL $name (unexpected validation failure)" }
  $script:passed++
  Write-Output "PASS $name"
}
function Legacy-Key($role, $ref) {
  $payload = @{role=$role; ref=$ref} | ConvertTo-Json -Compress
  $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload)).TrimEnd('=').Replace('+','-').Replace('/','_')
  return "fixture.$encoded.fixture"
}
try {
  Test-Configuration 'empty template fails closed' '' '' 'requires SUPABASE_URL'
  Test-Configuration 'production rejected' 'https://tgpdexoitemmpruepgyt.supabase.co' 'sb_publishable_fixture' 'production'
  Test-Configuration 'demo not silently selected' 'https://tmqhncduzlavgqoyjcmn.supabase.co' 'sb_publishable_fixture' 'separate, explicitly prepared'
  Test-Configuration 'secret key rejected' 'https://fixturedev.supabase.co' 'sb_secret_fixture' 'privileged'
  Test-Configuration 'service role JWT rejected' 'https://fixturedev.supabase.co' (Legacy-Key 'service_role' 'fixturedev') 'role or project'
  Test-Configuration 'mismatched anon rejected' 'https://fixturedev.supabase.co' (Legacy-Key 'anon' 'otherfixture') 'role or project'
  Test-Configuration 'matching synthetic anon accepted locally' 'https://fixturedev.supabase.co' (Legacy-Key 'anon' 'fixturedev') $null
  Test-Configuration 'synthetic publishable validates without network' 'https://fixturedev.supabase.co' 'sb_publishable_fixture' $null
  Test-Configuration 'malformed publishable rejected' 'https://fixturedev.supabase.co' 'sb_publishable_!!' 'Invalid publishable'
  '{invalid-private-value' | Set-Content $temporary
  try { & "$root/scripts/launch_local.ps1" -Environment Development -ConfigFile $temporary -ValidateOnly | Out-Null; throw 'Validation unexpectedly succeeded' }
  catch { if ($_.Exception.Message -ne 'Invalid local configuration JSON. Values are not logged.') { throw 'FAIL malformed JSON must not echo configuration' } }
  $passed++
  Write-Output 'PASS malformed JSON is redacted'
  Write-Output "$passed launch validation checks passed; synthetic values only, no hosted requests."
} finally { Remove-Item -LiteralPath $temporary -ErrorAction SilentlyContinue }
