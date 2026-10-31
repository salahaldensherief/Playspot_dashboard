$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('playspot-launch-test-' + [guid]::NewGuid().ToString('N') + '.json')
$passed = 0
# Any attempt to validate through a hosted HTTP call must fail this test.
function Invoke-WebRequest { throw 'TEST_FORBIDS_NETWORK' }
function Test-Configuration($name, $url, $key, $expectedError, $environment = 'Development') {
  @{SUPABASE_URL=$url; SUPABASE_ANON_KEY=$key} | ConvertTo-Json | Set-Content $temporary
  $failure = $null
  try { & "$root/scripts/launch_local.ps1" -Environment $environment -ConfigFile $temporary -ValidateOnly | Out-Null }
  catch { $failure = $_.Exception.Message }
  if ($expectedError) {
    if (-not $failure -or $failure -notlike "*$expectedError*") { throw "FAIL $name (unexpected validation result)" }
  } elseif ($failure) { throw "FAIL $name (unexpected validation failure)" }
  $script:passed++
  Write-Output "PASS $name"
}
function Legacy-Key($role, $ref, $issuer = '') {
  $payload = @{role=$role; ref=$ref; iss=$issuer} | ConvertTo-Json -Compress
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
  Test-Configuration 'explicit loopback public key accepted' 'http://127.0.0.1:56621' 'sb_publishable_fixture' $null 'Local'
  Test-Configuration 'local anon accepted' 'http://127.0.0.1:56621' (Legacy-Key 'anon' '' 'supabase-demo') $null 'Local'
  Test-Configuration 'local privileged JWT rejected' 'http://127.0.0.1:56621' (Legacy-Key 'service_role' '' 'supabase-demo') 'role or project' 'Local'
  Test-Configuration 'local secret rejected' 'http://127.0.0.1:56621' 'sb_secret_fixture' 'privileged' 'Local'
  Test-Configuration 'hosted key rejected in local mode' 'http://127.0.0.1:56621' (Legacy-Key 'anon' 'fixturedev') 'role or project' 'Local'
  foreach ($url in @('http://192.168.1.2:56621','http://127.0.0.1:54321','http://localhost:56621','http://127.0.0.1:56621/#fragment','https://fixturedev.supabase.co')) {
    Test-Configuration 'noncanonical local API rejected' $url 'sb_publishable_fixture' 'Local mode requires' 'Local'
  }
  Test-Configuration 'hosted mode rejects loopback' 'http://127.0.0.1:56621' 'sb_publishable_fixture' 'project URL'
  '{invalid-private-value' | Set-Content $temporary
  try { & "$root/scripts/launch_local.ps1" -Environment Development -ConfigFile $temporary -ValidateOnly | Out-Null; throw 'Validation unexpectedly succeeded' }
  catch { if ($_.Exception.Message -ne 'Invalid local configuration JSON. Values are not logged.') { throw 'FAIL malformed JSON must not echo configuration' } }
  $passed++
  Write-Output 'PASS malformed JSON is redacted'
  Write-Output "$passed launch validation checks passed; synthetic values only, no hosted requests."
} finally { Remove-Item -LiteralPath $temporary -ErrorAction SilentlyContinue }
