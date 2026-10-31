param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('Demo', 'Development', 'Local')]
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
  $fileName = switch ($Environment) {
    'Demo' { '.env.demo' }
    'Local' { '.env.isolated.json' }
    default { '.env.dev' }
  }
  $ConfigFile = Join-Path $projectRoot $fileName
}

if (-not (Test-Path -LiteralPath $ConfigFile -PathType Leaf)) {
  throw "Configuration file missing: $ConfigFile. See docs/LOCAL_DEVELOPMENT_LAUNCH.md."
}

$configPath = (Resolve-Path -LiteralPath $ConfigFile).Path
$values = @{}
if ([IO.Path]::GetExtension($configPath) -eq '.json') {
  try {
    $json = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
  } catch {
    throw 'Invalid local configuration JSON. Values are not logged.'
  }
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
if ($Environment -eq 'Local') {
  if ($uri.Scheme -ne 'http' -or $uri.Host -ne '127.0.0.1' -or $uri.Port -notin @(56621, 56821) -or
      $uri.AbsolutePath -ne '/' -or $uri.Query -or $uri.Fragment -or $uri.UserInfo) {
    throw 'Local mode requires an explicit isolated loopback API on port 56621 or 56821.'
  }
  $projectRef = 'playspot-local-acceptance'
} elseif ($uri.Scheme -ne 'https' -or $uri.Host -notmatch '^([a-z0-9]+)\.supabase\.co$' -or $uri.AbsolutePath -ne '/' -or $uri.Query -or $uri.Fragment -or $uri.UserInfo) {
  throw 'SUPABASE_URL must be a project URL such as https://PROJECT_REF.supabase.co.'
} else {
  $projectRef = $Matches[1]
}
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
  # Offline format check only. Opaque keys cannot prove project association locally.
  if ($key -notmatch '^sb_publishable_[A-Za-z0-9_-]+$') {
    throw 'Invalid publishable key format.'
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
  $matchesProject = if ($Environment -eq 'Local') {
    $claims.iss -eq 'supabase-demo' -and
      ([string]::IsNullOrEmpty($claims.ref) -or $claims.ref -eq $projectRef)
  } else { $claims.ref -eq $projectRef }
  if ($claims.role -ne 'anon' -or -not $matchesProject) {
    throw 'The anon key role or project reference does not match SUPABASE_URL.'
  }
}

Write-Output "Local format checks passed for $Environment project $projectRef; no hosted verification performed."
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
