param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('Demo', 'Development')]
  [string]$Environment,

  [string]$ConfigFile,

  [ValidateSet('chrome', 'edge')]
  [string]$Device = 'chrome',

  [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$productionRef = 'tgpdexoitemmpruepgyt'
$demoRef = 'tmqhncduzlavgqoyjcmn'

if (-not $ConfigFile) {
  $fileName = if ($Environment -eq 'Demo') { '.env.demo' } else { '.env.dev' }
  $ConfigFile = Join-Path $projectRoot $fileName
}

if (-not (Test-Path -LiteralPath $ConfigFile -PathType Leaf)) {
  throw "Configuration file missing: $ConfigFile. See docs/LOCAL_DEVELOPMENT_LAUNCH.md."
}

$configPath = (Resolve-Path -LiteralPath $ConfigFile).Path
$values = @{}
if ([IO.Path]::GetExtension($configPath) -eq '.json') {
  $json = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
  foreach ($name in @('SUPABASE_URL', 'SUPABASE_ANON_KEY')) {
    $values[$name] = [string]$json.$name
  }
} else {
  foreach ($line in Get-Content -LiteralPath $configPath) {
    if ($line -match '^\s*(SUPABASE_URL|SUPABASE_ANON_KEY)\s*=\s*(.*?)\s*$') {
      $values[$Matches[1]] = $Matches[2].Trim('"', "'")
    }
  }
}

$url = $values['SUPABASE_URL']
$key = $values['SUPABASE_ANON_KEY']
if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($key)) {
  throw 'Configuration requires SUPABASE_URL and SUPABASE_ANON_KEY.'
}

$uri = [uri]$url
if ($uri.Scheme -ne 'https' -or $uri.Host -notmatch '^([a-z0-9]+)\.supabase\.co$' -or $uri.AbsolutePath -ne '/' -or $uri.Query) {
  throw 'SUPABASE_URL must be a project URL such as https://PROJECT_REF.supabase.co.'
}
$projectRef = $Matches[1]
if ($projectRef -eq $productionRef) {
  throw 'The production Supabase project is forbidden for local development builds.'
}
if ($Environment -eq 'Demo' -and $projectRef -ne $demoRef) {
  throw 'Demo mode requires the separate playspot-demo project.'
}
if ($Environment -eq 'Development' -and $projectRef -eq $demoRef) {
  throw 'Development mode requires a separate, explicitly prepared development project. Use Demo mode for the existing demo project.'
}

if ($key.StartsWith('sb_secret_')) {
  throw 'A privileged Supabase key cannot be used in Flutter.'
}
if ($key.StartsWith('sb_publishable_')) {
  try {
    Invoke-WebRequest -Uri "$($uri.GetLeftPart('Authority'))/auth/v1/settings" -Headers @{ apikey = $key } -TimeoutSec 10 -UseBasicParsing | Out-Null
  } catch {
    throw 'The publishable key could not be verified against the selected project.'
  }
} else {
  $parts = $key.Split('.')
  if ($parts.Length -ne 3) { throw 'Expected a Supabase publishable or legacy anon key.' }
  try {
    $payload = $parts[1].Replace('-', '+').Replace('_', '/')
    $payload = $payload.PadRight($payload.Length + ((4 - $payload.Length % 4) % 4), '=')
    $claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
  } catch {
    throw 'The legacy anon key could not be decoded.'
  }
  if ($claims.role -ne 'anon' -or $claims.ref -ne $projectRef) {
    throw 'The anon key role or project reference does not match SUPABASE_URL.'
  }
}

Write-Output "Validated $Environment configuration for project $projectRef."
if ($ValidateOnly) { return }

$temporaryDefines = Join-Path ([IO.Path]::GetTempPath()) ("playspot-dashboard-defines-$([guid]::NewGuid().ToString('N')).json")
try {
  @{ SUPABASE_URL = $url; SUPABASE_ANON_KEY = $key } |
    ConvertTo-Json -Compress |
    Set-Content -LiteralPath $temporaryDefines -Encoding utf8
  Push-Location $projectRoot
  try {
    & flutter run -d $Device "--dart-define-from-file=$temporaryDefines"
    if ($LASTEXITCODE -ne 0) { throw "Flutter exited with code $LASTEXITCODE." }
  } finally {
    Pop-Location
  }
} finally {
  Remove-Item -LiteralPath $temporaryDefines -ErrorAction SilentlyContinue
}
