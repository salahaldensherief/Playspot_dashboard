param(
 [Parameter(Mandatory=$true)][string]$PrivateDirectory,
 [Parameter(Mandatory=$true)][string]$Report
)
$ErrorActionPreference='Stop'
$status=Get-Content -Raw -LiteralPath (Join-Path $PrivateDirectory 'status.json') | ConvertFrom-Json
if($status.API_URL -ne 'http://127.0.0.1:56821'){throw 'Only the owned isolated loopback API is allowed'}
$db=[uri]$status.DB_URL
if($db.Host -ne '127.0.0.1' -or $db.Port -ne 56822){throw 'Wrong isolated database'}
# New synthetic input per run; preserve all earlier inputs and database rows.
$inputName='refund-client-input-'+[guid]::NewGuid().ToString('N')+'.json'
$now=[DateTime]::UtcNow.AddMinutes(2)
$startUtc=[DateTime]::new($now.Ticks-($now.Ticks % [TimeSpan]::TicksPerMinute),[DateTimeKind]::Utc).AddMinutes(1)
$cairo=[TimeZoneInfo]::FindSystemTimeZoneById('Egypt Standard Time')
$inputData=@{
 start=[TimeZoneInfo]::ConvertTimeFromUtc($startUtc,$cairo).ToString('yyyy-MM-ddTHH:mm:ss')
 end=[TimeZoneInfo]::ConvertTimeFromUtc($startUtc.AddHours(1),$cairo).ToString('yyyy-MM-ddTHH:mm:ss')
 collectionOperation=[guid]::NewGuid().ToString()
}
[IO.File]::WriteAllText((Join-Path $PrivateDirectory $inputName),($inputData | ConvertTo-Json))
$names=@('PLAYSPOT_LOCAL_TEST_DIR','PLAYSPOT_LOCAL_TEST_REPORT','PLAYSPOT_LOCAL_TEST_INPUT')
$previous=@{}
foreach($name in $names){$previous[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
try{
 $env:PLAYSPOT_LOCAL_TEST_DIR=[IO.Path]::GetFullPath($PrivateDirectory)
 $env:PLAYSPOT_LOCAL_TEST_REPORT=[IO.Path]::GetFullPath($Report)
 $env:PLAYSPOT_LOCAL_TEST_INPUT=$inputName
 Push-Location (Join-Path $PSScriptRoot '..')
 try{
  & flutter test --no-pub test/local/booking_refund_local_acceptance_test.dart --reporter expanded
  if($LASTEXITCODE -ne 0){throw 'Local refund acceptance failed; preserve input and diagnostics'}
 }finally{Pop-Location}
}finally{
 foreach($name in $names){[Environment]::SetEnvironmentVariable($name,$previous[$name],'Process')}
}
